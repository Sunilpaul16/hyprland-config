import json
import os
from pathlib import Path
import sys


def environment(root, current):
    for module in ("Multimedia", "State", "Shaders"):
        if not (root / "qml/Caelestia" / module / "qmldir").is_file():
            raise RuntimeError(f"Missing Caelestia runtime module {module} under {root}")
    python_dir = root / f"cli/lib/python{sys.version_info.major}.{sys.version_info.minor}/site-packages"
    if not (python_dir / "caelestia/__main__.py").is_file():
        raise RuntimeError(f"Missing Caelestia CLI for this Python version under {root}")
    result = dict(current)
    for key, path in {
        "QML_IMPORT_PATH": root / "qml",
        "LD_LIBRARY_PATH": root / "qml/Caelestia/lib",
        "PYTHONPATH": python_dir,
        "PATH": root / "cli/bin",
    }.items():
        result[key] = str(path) + (os.pathsep + result[key] if result.get(key) else "")
    result["CAELESTIA_LIB_DIR"] = str(root / "lib/caelestia")
    return result


def main():
    if len(sys.argv) < 2:
        raise SystemExit("Pass a command to run with the pinned Caelestia runtime.")
    specification = json.loads(Path(__file__).with_name("runtime.json").read_text())
    default = Path.home() / ".local/share/caelestia/runtime" / specification["shell_commit"][:8]
    root = Path(os.environ.get("CAELESTIA_RUNTIME_ROOT", default))
    try:
        prepared = environment(root, os.environ)
    except RuntimeError as error:
        raise SystemExit(str(error))
    command = sys.argv[1:]
    if command[0] == "caelestia":
        command = [sys.executable, "-m", "caelestia", *command[1:]]
    os.execvpe(command[0], command, prepared)


if __name__ == "__main__":
    main()
