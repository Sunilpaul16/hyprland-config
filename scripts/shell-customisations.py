import argparse
import difflib
import json
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent.parent
CUSTOM = ROOT / "customisations/shell"
SHELL_DIRS = {"assets", "components", "daemons", "modules", "services", "utils"}


def git(source, *args):
    return subprocess.check_output(["git", "-C", str(source), *args])


def custom_file(entry):
    return CUSTOM / entry["source"]


def write_patches(manifest):
    patches = {}
    for entry in manifest["files"]:
        path = entry["path"]
        base = [] if entry["added"] else (CUSTOM / "base" / path).read_text().splitlines(True)
        local = custom_file(entry).read_text().splitlines(True)
        patch = f"diff --git a/{path} b/{path}\n"
        if entry["added"]:
            patch += "new file mode 100644\n"
        patch += "".join(difflib.unified_diff(
            base, local, fromfile="/dev/null" if entry["added"] else f"a/{path}", tofile=f"b/{path}",
        ))
        patches.setdefault(entry["feature"], []).append(patch)
    destination = CUSTOM / "patches"
    destination.mkdir(exist_ok=True)
    for feature, parts in sorted(patches.items()):
        (destination / f"{feature}.patch").write_text("".join(parts))
    print(f"Updated {len(patches)} feature patches in {destination}")


def prepare(source, ref):
    manifest = json.loads((CUSTOM / "manifest.json").read_text())
    revision = git(source, "rev-parse", "--verify", f"{ref}^{{commit}}").decode().strip()
    paths = set(git(source, "ls-tree", "-r", "--name-only", revision).decode().splitlines())
    changes = git(source, "diff", "--name-status", "-M", manifest["base_commit"], revision).decode()
    renames = {}
    for line in changes.splitlines():
        parts = line.split("\t")
        if parts[0].startswith("R"):
            renames[parts[1]] = parts[2]
    merged = {}
    conflicts = []
    for entry in manifest["files"]:
        path = entry["path"]
        target = renames.get(path, path)
        local = custom_file(entry).read_bytes()
        label = f"[{entry['feature']}] {path}"
        if entry["added"]:
            if target not in paths or git(source, "show", f"{revision}:{target}") == local:
                merged[target] = local
                print(f"LOCAL FILE  {label}")
            else:
                conflicts.append(path)
                print(f"CONFLICT    {label}: also added upstream")
            continue
        if target not in paths:
            conflicts.append(path)
            print(f"CONFLICT    {label}: removed upstream; port its behaviour manually")
            continue
        upstream = git(source, "show", f"{revision}:{target}")
        with tempfile.TemporaryDirectory(prefix="shell-merge-") as directory:
            incoming = Path(directory) / "upstream"
            incoming.write_bytes(upstream)
            result = subprocess.run([
                "git", "merge-file", "-p", str(custom_file(entry)),
                str(CUSTOM / "base" / path), str(incoming),
            ], capture_output=True)
        if result.returncode:
            if result.returncode < 0 or result.returncode > 127:
                raise RuntimeError(result.stderr.decode())
            conflicts.append(path)
            print(f"CONFLICT    {label}: overlapping edits")
        else:
            merged[target] = result.stdout
            suffix = f" -> {target}" if target != path else ""
            print(f"CLEAN       {label}{suffix}")
    return revision, paths, merged, conflicts


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("check", "build", "patches"))
    parser.add_argument("--source", type=Path, default=ROOT.parent / "shell")
    parser.add_argument("--ref", help="Upstream Git ref; defaults to the recorded baseline")
    parser.add_argument("--output", type=Path, help="New directory for the generated shell")
    args = parser.parse_args()
    manifest = json.loads((CUSTOM / "manifest.json").read_text())
    if args.action in {"build", "patches"} and (CUSTOM / "pending-update.json").exists():
        parser.error("upstream merge is pending; see UPSTREAM-MERGE.md before building or refreshing patches")
    if args.action == "patches":
        write_patches(manifest)
        return
    if args.action == "build":
        if args.output is None:
            parser.error("build requires --output pointing to a new directory")
        if args.output.exists() or args.output.is_symlink():
            parser.error("output already exists; choose a new directory")
    revision, paths, merged, conflicts = prepare(args.source, args.ref or manifest["base_commit"])
    print(f"\n{len(merged)} clean files; {len(conflicts)} conflicts. Upstream: {revision}")
    if conflicts:
        raise SystemExit(1)
    if args.action == "build":
        selected = {p for p in paths if p.split("/")[0] in SHELL_DIRS or p in {"shell.qml", "LICENSE"}}
        selected.update(merged)
        args.output.mkdir(parents=True)
        for path in sorted(selected):
            destination = args.output / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(merged[path] if path in merged else git(args.source, "show", f"{revision}:{path}"))
        print(f"Generated shell: {args.output.resolve()}. Not installed or runtime-tested.")


if __name__ == "__main__":
    main()
