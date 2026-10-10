#!/usr/bin/env python3
"""Build the pinned InputActions plugin for the running Arch Hyprland session."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

SOURCE_COMMIT = "78f97531e8d86d32aafbaa7fa0b7fc205829271f"


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def output(*args):
    return subprocess.check_output(args, text=True)


def main():
    repo = Path(__file__).resolve().parent.parent
    running = json.loads(output("hyprctl", "version", "-j"))
    header = Path("/usr/include/hyprland/src/version.h").read_text()
    header_commit = re.search(r'#define GIT_COMMIT_HASH\s+"([^"]+)"', header).group(1)
    if header_commit != running["commit"]:
        raise SystemExit("Hyprland headers differ from the running session. Log into the updated Hyprland before rebuilding.")
    root = Path.home() / ".local/share/inputactions/hyprland"
    destination = root / running["abiHash"] / SOURCE_COMMIT
    # Never overwrite a shared library mapped into the current compositor.
    loaded = output("hyprctl", "plugin", "list")
    if "InputActions" in loaded:
        raise SystemExit("InputActions is already loaded. Unload it before rebuilding; see README.md.")
    with tempfile.TemporaryDirectory(prefix="files-gestures-") as directory:
        work = Path(directory)
        dependencies = work / "dependencies"
        dependencies.mkdir()
        metadata = output("pacman", "-Sp", "--print-format", "%n %l %h", "extra-cmake-modules", "yaml-cpp")
        for line in metadata.splitlines():
            name, url, expected_hash = line.split()
            archive = work / url.rsplit("/", 1)[1]
            run("curl", "--fail", "--location", "--output", str(archive), url)
            if hashlib.sha256(archive.read_bytes()).hexdigest() != expected_hash:
                raise SystemExit(f"Checksum verification failed for {name}")
            run("bsdtar", "-xf", str(archive), "-C", str(dependencies), "usr")
        source = work / "source"
        run("git", "clone", "https://github.com/InputActions/hyprland.git", str(source))
        run("git", "-C", str(source), "checkout", "--detach", SOURCE_COMMIT)
        run("git", "-C", str(source), "submodule", "update", "--init", "--recursive")
        # Upstream's public precompiled header includes yaml-cpp, while its
        # dependency is private to the sibling core target. Expose it here.
        cmake = source / "src/CMakeLists.txt"
        with cmake.open("a") as stream:
            stream.write('\nfind_package(yaml-cpp REQUIRED)\n'
                         'target_link_libraries(inputactions_hyprland PRIVATE yaml-cpp::yaml-cpp)\n'
                         'set_target_properties(inputactions_hyprland PROPERTIES INSTALL_RPATH "$ORIGIN" INSTALL_RPATH_USE_LINK_PATH FALSE)\n')
        build = work / "build"
        stage = work / "stage"
        run("cmake", "-S", str(source), "-B", str(build),
            f"-DCMAKE_PREFIX_PATH={dependencies / 'usr'}", "-DCMAKE_BUILD_TYPE=Release")
        run("cmake", "--build", str(build), "--parallel", "3")
        run("cmake", "--install", str(build), "--prefix", str(stage))
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(stage / "lib/libinputactions_hyprland.so", destination)
        runtime = list((dependencies / "usr/lib").glob("libyaml-cpp.so.*"))
        for library in runtime:
            shutil.copy2(library, destination / library.name)
    (root / "build.json").write_text(json.dumps({
        "abiHash": running["abiHash"], "source": SOURCE_COMMIT,
        "plugin": str(destination / "libinputactions_hyprland.so"),
    }, indent=2) + "\n")
    print(f"Plugin built: {destination}")
    print("Restore configuration with install.py if needed, then run:")
    print("python3 ~/.config/caelestia/load-files-gestures.py")


if __name__ == "__main__":
    main()
