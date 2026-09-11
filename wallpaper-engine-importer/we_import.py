#!/usr/bin/env python3
"""Convert local Wallpaper Engine Workshop items into ordinary video files."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


APP_ID = "431960"
SUPPORTED_TYPES = {"video", "web", "scene"}
ROOT = Path(__file__).resolve().parent
DEFAULT_OUTPUT = ROOT / "output"
DEFAULT_MANIFEST = ROOT / "manifest.json"


class ImportFailure(RuntimeError):
    pass


@dataclass(frozen=True)
class Project:
    workshop_id: str
    kind: str
    title: str
    entry: Path
    directory: Path
    preview: Path | None

    def serializable(self) -> dict[str, Any]:
        data = asdict(self)
        for key in ("entry", "directory", "preview"):
            data[key] = str(data[key]) if data[key] is not None else None
        return data


def steam_roots() -> list[Path]:
    home = Path.home()
    candidates = [
        home / ".local/share/Steam",
        home / ".steam/steam",
        home / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
    ]
    override = os.environ.get("WE_STEAM_ROOT")
    if override:
        candidates.insert(0, Path(override).expanduser())
    found: list[Path] = []
    for root in candidates:
        resolved = root.resolve()
        if resolved.is_dir() and resolved not in found:
            found.append(resolved)
    return found


def workshop_roots() -> list[Path]:
    override = os.environ.get("WE_WORKSHOP_DIR")
    if override:
        path = Path(override).expanduser().resolve()
        return [path] if path.is_dir() else []
    return [
        path
        for root in steam_roots()
        if (path := root / "steamapps/workshop/content" / APP_ID).is_dir()
    ]


def safe_child(directory: Path, relative: str) -> Path:
    candidate = (directory / relative).resolve()
    try:
        candidate.relative_to(directory.resolve())
    except ValueError as exc:
        raise ImportFailure(f"project entry escapes its Workshop directory: {relative}") from exc
    if not candidate.is_file():
        raise ImportFailure(f"project entry does not exist: {candidate}")
    return candidate


def read_project(project_file: Path) -> Project:
    try:
        data = json.loads(project_file.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ImportFailure(f"cannot read {project_file}: {exc}") from exc
    directory = project_file.parent.resolve()
    kind = str(data.get("type", "unknown")).strip().lower()
    title = str(data.get("title") or directory.name).strip()
    entry_name = str(data.get("file") or "").strip()
    if not entry_name:
        raise ImportFailure(f"{project_file} has no file entry")
    # Workshop scene sources are packed as scene.pkg while project.json keeps
    # the editor-time scene.json name.
    if kind == "scene" and not (directory / entry_name).is_file():
        packages = sorted(directory.glob("*.pkg"))
        if len(packages) == 1:
            entry_name = packages[0].name
        else:
            entry_name = "scene.pkg"
    preview_name = str(data.get("preview") or "").strip()
    preview = None
    if preview_name:
        try:
            preview = safe_child(directory, preview_name)
        except ImportFailure:
            pass
    return Project(
        workshop_id=directory.name,
        kind=kind,
        title=title,
        entry=safe_child(directory, entry_name),
        directory=directory,
        preview=preview,
    )


def scan_projects() -> list[Project]:
    projects: dict[str, Project] = {}
    for root in workshop_roots():
        for project_file in root.glob("*/project.json"):
            try:
                project = read_project(project_file)
            except ImportFailure as exc:
                print(f"warning: {exc}", file=sys.stderr)
                continue
            projects.setdefault(project.workshop_id, project)
    return sorted(projects.values(), key=lambda item: (item.kind, item.title.casefold()))


def find_project(workshop_id: str) -> Project:
    if not workshop_id.isdigit():
        raise ImportFailure("Workshop ID must contain digits only")
    for project in scan_projects():
        if project.workshop_id == workshop_id:
            return project
    raise ImportFailure(f"Workshop item {workshop_id} is not downloaded")


def slug(value: str) -> str:
    value = re.sub(r"[\x00-\x1f/\\:*?\"<>|]+", " ", value)
    value = re.sub(r"\s+", " ", value).strip(" .")
    return value[:120] or "Wallpaper"


def output_path(project: Project, output_dir: Path, extension: str = ".mp4") -> Path:
    return output_dir / f"WE - {slug(project.title)} [{project.workshop_id}]{extension}"


def run(command: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None) -> None:
    try:
        subprocess.run(command, cwd=cwd, env=env, check=True)
    except FileNotFoundError as exc:
        raise ImportFailure(f"missing required program: {command[0]}") from exc
    except subprocess.CalledProcessError as exc:
        raise ImportFailure(f"command failed ({exc.returncode}): {' '.join(command)}") from exc


def media_info(path: Path) -> dict[str, Any]:
    command = [
        "ffprobe", "-v", "error", "-show_entries",
        "format=duration:stream=index,codec_type,codec_name,width,height,r_frame_rate",
        "-of", "json", str(path),
    ]
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        return json.loads(result.stdout)
    except (FileNotFoundError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        raise ImportFailure(f"ffprobe could not validate {path}: {exc}") from exc


def package_entries(path: Path) -> list[tuple[str, int, int]]:
    """Read the simple Wallpaper Engine PKGV file table."""
    try:
        with path.open("rb") as source:
            total_size = path.stat().st_size

            def read_u32() -> int:
                raw = source.read(4)
                if len(raw) != 4:
                    raise ImportFailure(f"truncated package header: {path}")
                return struct.unpack("<I", raw)[0]

            def read_string() -> str:
                length = read_u32()
                if length > 1024 * 1024:
                    raise ImportFailure(f"invalid package string length in {path}")
                raw = source.read(length)
                if len(raw) != length:
                    raise ImportFailure(f"truncated package string in {path}")
                return raw.decode("utf-8")

            header = read_string()
            if not header.startswith("PKGV"):
                raise ImportFailure(f"unsupported scene package header: {header!r}")
            count = read_u32()
            if count > 100_000:
                raise ImportFailure(f"unreasonable file count in {path}: {count}")
            relative_entries = [(read_string(), read_u32(), read_u32()) for _ in range(count)]
            base = source.tell()
            entries = []
            for name, offset, length in relative_entries:
                absolute = base + offset
                if absolute < base or length < 0 or absolute + length > total_size:
                    raise ImportFailure(f"invalid package entry bounds: {name}")
                entries.append((name, absolute, length))
            return entries
    except (OSError, UnicodeDecodeError) as exc:
        raise ImportFailure(f"cannot inspect scene package {path}: {exc}") from exc


def scene_compatibility(project: Project) -> list[str]:
    """Return known reasons the current scene renderer cannot reproduce a project."""
    issues: list[str] = []
    entries = package_entries(project.entry)
    with project.entry.open("rb") as source:
        for name, offset, length in entries:
            if not name.startswith("particles/") or not name.endswith(".json"):
                continue
            source.seek(offset)
            try:
                definition = json.loads(source.read(length))
            except (UnicodeDecodeError, json.JSONDecodeError):
                continue
            children = definition.get("children")
            if isinstance(children, list) and children:
                kinds = sorted({str(child.get("type", "static")) for child in children if isinstance(child, dict)})
                issues.append(f"{name} uses unimplemented child particles ({', '.join(kinds)})")
    return issues


def atomic_copy(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + f".part-{os.getpid()}")
    shutil.copy2(source, temporary)
    os.replace(temporary, destination)


def import_video(project: Project, destination: Path) -> dict[str, Any]:
    info = media_info(project.entry)
    video_streams = [s for s in info.get("streams", []) if s.get("codec_type") == "video"]
    if not video_streams:
        raise ImportFailure(f"no video stream found in {project.entry}")
    source_suffix = project.entry.suffix.lower()
    if source_suffix == ".mp4":
        atomic_copy(project.entry, destination)
        method = "lossless-copy"
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_name(destination.name + f".part-{os.getpid()}.mp4")
        run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(project.entry),
             "-map", "0:v:0", "-map", "0:a?", "-c", "copy", "-movflags", "+faststart", str(temporary)])
        os.replace(temporary, destination)
        method = "lossless-remux"
    return {"method": method, "media": info}


class DevTools:
    """Minimal localhost WebSocket client for Chrome DevTools Protocol."""

    def __init__(self, url: str):
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "ws" or parsed.hostname not in {"127.0.0.1", "localhost"}:
            raise ImportFailure(f"refusing non-local DevTools endpoint: {url}")
        self.sock = socket.create_connection((parsed.hostname, parsed.port or 80), timeout=10)
        key = base64.b64encode(os.urandom(16)).decode()
        target = parsed.path + (f"?{parsed.query}" if parsed.query else "")
        request = (
            f"GET {target} HTTP/1.1\r\n"
            f"Host: {parsed.hostname}:{parsed.port or 80}\r\n"
            "Upgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
        )
        self.sock.sendall(request.encode())
        response = self._recv_until(b"\r\n\r\n")
        if b" 101 " not in response.split(b"\r\n", 1)[0]:
            raise ImportFailure("Chrome rejected the DevTools WebSocket connection")
        self.next_id = 1

    def _recv_until(self, marker: bytes) -> bytes:
        data = b""
        while marker not in data:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise ImportFailure("Chrome closed the DevTools connection")
            data += chunk
        return data

    def _exact(self, length: int) -> bytes:
        data = b""
        while len(data) < length:
            chunk = self.sock.recv(length - len(data))
            if not chunk:
                raise ImportFailure("Chrome closed the DevTools connection")
            data += chunk
        return data

    def send(self, payload: dict[str, Any]) -> None:
        raw = json.dumps(payload, separators=(",", ":")).encode()
        mask = os.urandom(4)
        header = bytearray([0x81])
        length = len(raw)
        if length < 126:
            header.append(0x80 | length)
        elif length < 65536:
            header.append(0x80 | 126)
            header.extend(struct.pack("!H", length))
        else:
            header.append(0x80 | 127)
            header.extend(struct.pack("!Q", length))
        masked = bytes(byte ^ mask[index % 4] for index, byte in enumerate(raw))
        self.sock.sendall(bytes(header) + mask + masked)

    def receive(self) -> dict[str, Any]:
        while True:
            first, second = self._exact(2)
            opcode = first & 0x0F
            length = second & 0x7F
            if length == 126:
                length = struct.unpack("!H", self._exact(2))[0]
            elif length == 127:
                length = struct.unpack("!Q", self._exact(8))[0]
            mask = self._exact(4) if second & 0x80 else b""
            data = self._exact(length)
            if mask:
                data = bytes(byte ^ mask[index % 4] for index, byte in enumerate(data))
            if opcode == 0x9:
                self.send({})
                continue
            if opcode == 0x8:
                raise ImportFailure("Chrome closed the DevTools connection")
            if opcode == 0x1:
                return json.loads(data)

    def call(self, method: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
        call_id = self.next_id
        self.next_id += 1
        self.send({"id": call_id, "method": method, "params": params or {}})
        while True:
            message = self.receive()
            if message.get("id") == call_id:
                if "error" in message:
                    raise ImportFailure(f"Chrome {method} failed: {message['error']}")
                return message.get("result", {})

    def close(self) -> None:
        self.sock.close()


def chrome_binary() -> str:
    override = os.environ.get("WE_CHROME")
    candidates = [override, "google-chrome-stable", "google-chrome", "chromium", "chromium-browser"]
    for candidate in candidates:
        if candidate and (found := shutil.which(candidate)):
            return found
    raise ImportFailure("Chrome/Chromium is required for web wallpaper conversion")


def wait_for_devtools(port_file: Path, process: subprocess.Popen[bytes]) -> tuple[str, str]:
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise ImportFailure(f"Chrome exited before startup (status {process.returncode})")
        if port_file.is_file():
            lines = port_file.read_text().splitlines()
            if len(lines) >= 2:
                return lines[0], lines[1]
        time.sleep(0.05)
    raise ImportFailure("timed out waiting for Chrome DevTools")


def import_web(project: Project, destination: Path, width: int, height: int,
               fps: int, duration: float) -> dict[str, Any]:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="we-import-chrome-") as temp_name:
        profile = Path(temp_name)
        browser = chrome_binary()
        page_url = project.entry.as_uri()
        browser_profile = str(profile)
        chrome_prefix: list[str] = []
        # Hide the user's home and the rest of the Workshop collection from
        # third-party wallpaper JavaScript. Chrome retains its own sandbox too.
        if (bubblewrap := shutil.which("bwrap")):
            relative_entry = project.entry.relative_to(project.directory)
            page_url = "file:///wallpaper/" + urllib.parse.quote(relative_entry.as_posix())
            browser_profile = "/profile"
            chrome_prefix = [
                bubblewrap, "--die-with-parent", "--new-session", "--unshare-pid",
                "--unshare-ipc", "--unshare-uts", "--ro-bind", "/usr", "/usr",
                "--ro-bind", "/opt/google/chrome", "/opt/google/chrome",
                "--ro-bind", "/etc", "/etc", "--symlink", "usr/bin", "/bin",
                "--symlink", "usr/lib", "/lib", "--symlink", "usr/lib", "/lib64",
                "--dev", "/dev", "--proc", "/proc", "--tmpfs", "/tmp",
                "--tmpfs", "/home", "--ro-bind", str(project.directory), "/wallpaper",
                "--bind", str(profile), "/profile", "--chdir", "/wallpaper",
            ]
        chrome = subprocess.Popen(chrome_prefix + [
            browser, "--headless=new", "--remote-debugging-port=0",
            f"--user-data-dir={browser_profile}", f"--window-size={width},{height}",
            "--hide-scrollbars", "--mute-audio", "--disable-extensions", "--disable-sync",
            "--disable-background-networking", "--disable-component-update", "--no-first-run",
            "--no-default-browser-check", "--disable-quic", "--disable-breakpad",
            "--disable-crash-reporter", "--proxy-server=http://127.0.0.1:9", "about:blank",
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        encoder: subprocess.Popen[bytes] | None = None
        devtools: DevTools | None = None
        try:
            port, browser_path = wait_for_devtools(profile / "DevToolsActivePort", chrome)
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list", timeout=5) as response:
                targets = json.load(response)
            page = next((target for target in targets if target.get("type") == "page"), None)
            if not page:
                raise ImportFailure("Chrome created no capturable page")
            devtools = DevTools(page["webSocketDebuggerUrl"])
            devtools.call("Page.enable")
            devtools.call("Network.enable")
            devtools.call("Network.setBlockedURLs", {
                "urls": ["http://*", "https://*", "ftp://*", "ws://*", "wss://*"]
            })
            devtools.call("Emulation.setDeviceMetricsOverride", {
                "width": width, "height": height, "deviceScaleFactor": 1, "mobile": False,
            })
            devtools.call("Page.navigate", {"url": page_url})
            time.sleep(1.0)
            temporary = destination.with_name(destination.name + f".part-{os.getpid()}.mp4")
            encoder = subprocess.Popen([
                "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                "-f", "image2pipe", "-framerate", str(fps), "-vcodec", "png", "-i", "pipe:0",
                "-an", "-c:v", "libx264", "-preset", "medium", "-crf", "18",
                "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(temporary),
            ], stdin=subprocess.PIPE)
            assert encoder.stdin is not None
            frames = max(1, round(duration * fps))
            interval = 1.0 / fps
            next_frame = time.monotonic()
            for _ in range(frames):
                result = devtools.call("Page.captureScreenshot", {
                    "format": "png", "fromSurface": True, "captureBeyondViewport": False,
                })
                encoder.stdin.write(base64.b64decode(result["data"]))
                next_frame += interval
                delay = next_frame - time.monotonic()
                if delay > 0:
                    time.sleep(delay)
            encoder.stdin.close()
            status = encoder.wait()
            if status != 0:
                raise ImportFailure(f"FFmpeg web encoder exited with status {status}")
            os.replace(temporary, destination)
        finally:
            if devtools:
                devtools.close()
            if encoder and encoder.poll() is None:
                encoder.kill()
            chrome.terminate()
            try:
                chrome.wait(timeout=5)
            except subprocess.TimeoutExpired:
                chrome.kill()
    return {"method": "headless-chrome-capture", "width": width, "height": height,
            "fps": fps, "duration": duration}


def scene_renderer() -> Path:
    override = os.environ.get("WE_SCENE_RENDERER")
    candidates = [Path(override).expanduser() if override else None]
    installed = shutil.which("linux-wallpaperengine")
    if installed:
        candidates.append(Path(installed))
    candidates.append(ROOT / ".runtime/build/output/linux-wallpaperengine")
    candidates.append(ROOT / ".runtime/linux-wallpaperengine/linux-wallpaperengine")
    for candidate in candidates:
        if candidate and candidate.is_file() and os.access(candidate, os.X_OK):
            return candidate.resolve()
    raise ImportFailure(
        "scene exporter not found; install linux-wallpaperengine-git or set WE_SCENE_RENDERER"
    )


def wallpaper_engine_assets() -> Path:
    override = os.environ.get("WE_ASSETS_DIR")
    if override and Path(override).expanduser().is_dir():
        return Path(override).expanduser().resolve()
    for root in steam_roots():
        candidate = root / "steamapps/common/wallpaper_engine/assets"
        if candidate.is_dir():
            return candidate.resolve()
    raise ImportFailure("Wallpaper Engine assets directory was not found")


def import_scene(project: Project, destination: Path, width: int, height: int,
                 duration: float) -> dict[str, Any]:
    issues = scene_compatibility(project)
    if issues:
        summary = "; ".join(issues[:3])
        if len(issues) > 3:
            summary += f"; and {len(issues) - 3} more"
        raise ImportFailure(f"scene is not faithfully renderable: {summary}")
    renderer = scene_renderer()
    runtime = renderer.parent
    generated = runtime / "output.webm"
    if generated.exists():
        generated.unlink()
    command = [str(renderer), "--silent", "--assets-dir", str(wallpaper_engine_assets()),
               "--window", f"0x0x{width}x{height}", str(project.directory)]
    environment = os.environ.copy()
    export_seconds = max(1, min(600, round(duration)))
    environment["WE_EXPORT_SECONDS"] = str(export_seconds)
    local_lib = runtime / "lib"
    if local_lib.is_dir():
        environment["LD_LIBRARY_PATH"] = f"{local_lib}:{environment.get('LD_LIBRARY_PATH', '')}"
    run(command, cwd=runtime, env=environment)
    if not generated.is_file():
        raise ImportFailure(
            "renderer produced no output.webm; it must be built with CMake -DDEMOMODE=1"
        )
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + f".part-{os.getpid()}.mp4")
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(generated),
         "-an", "-c:v", "libx264", "-preset", "medium", "-crf", "18",
         "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(temporary)])
    os.replace(temporary, destination)
    generated.unlink(missing_ok=True)
    return {"method": "linux-wallpaperengine-demomode", "requested_width": width,
            "requested_height": height, "duration": export_seconds, "fps": 30}


def load_manifest(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {"version": 1, "imports": {}}
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {"version": 1, "imports": {}}


def save_manifest(path: Path, manifest: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + f".part-{os.getpid()}")
    temporary.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    os.replace(temporary, path)


def fingerprint(project: Project) -> str:
    digest = hashlib.sha256()
    for path in sorted(project.directory.rglob("*")):
        if path.is_file():
            stat = path.stat()
            digest.update(str(path.relative_to(project.directory)).encode())
            digest.update(str(stat.st_size).encode())
            digest.update(str(stat.st_mtime_ns).encode())
    return digest.hexdigest()


def do_import(args: argparse.Namespace) -> None:
    project = find_project(args.workshop_id)
    if project.kind not in SUPPORTED_TYPES:
        raise ImportFailure(f"{project.kind} wallpapers are intentionally unsupported")
    output_dir = args.output_dir.expanduser().resolve()
    destination = output_path(project, output_dir)
    print(f"Importing {project.kind}: {project.title} [{project.workshop_id}]")
    if project.kind == "video":
        details = import_video(project, destination)
    elif project.kind == "web":
        details = import_web(project, destination, args.width, args.height, args.fps, args.duration)
    else:
        details = import_scene(project, destination, args.width, args.height, args.duration)
    info = media_info(destination)
    manifest = load_manifest(args.manifest)
    manifest.setdefault("imports", {})[project.workshop_id] = {
        "project": project.serializable(), "output": str(destination),
        "source_fingerprint": fingerprint(project), "imported_at": int(time.time()),
        "details": details, "output_media": info,
    }
    save_manifest(args.manifest, manifest)
    print(destination)


def print_scan(json_output: bool) -> None:
    projects = scan_projects()
    if json_output:
        print(json.dumps([project.serializable() for project in projects], ensure_ascii=False, indent=2))
        return
    counts: dict[str, int] = {}
    for project in projects:
        counts[project.kind] = counts.get(project.kind, 0) + 1
        marker = "supported" if project.kind in SUPPORTED_TYPES else "skipped"
        print(f"{project.workshop_id}\t{project.kind:11}\t{marker:9}\t{project.title}")
    print("\n" + ", ".join(f"{kind}: {count}" for kind, count in sorted(counts.items())))


def parser() -> argparse.ArgumentParser:
    cli = argparse.ArgumentParser(description=__doc__)
    sub = cli.add_subparsers(dest="command", required=True)
    scan = sub.add_parser("scan", help="list downloaded Workshop wallpapers")
    scan.add_argument("--json", action="store_true")
    convert = sub.add_parser("import", help="convert one downloaded Workshop wallpaper")
    convert.add_argument("workshop_id")
    convert.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    convert.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    convert.add_argument("--width", type=int, default=1280)
    convert.add_argument("--height", type=int, default=720)
    convert.add_argument("--fps", type=int, default=15, help="web capture FPS")
    convert.add_argument("--duration", type=float, default=5.0, help="capture/export seconds")
    return cli


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "scan":
            print_scan(args.json)
        else:
            if args.width < 2 or args.height < 2 or args.fps < 1 or args.duration <= 0:
                raise ImportFailure("width, height, FPS and duration must be positive")
            do_import(args)
    except ImportFailure as exc:
        print(f"we-import: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
