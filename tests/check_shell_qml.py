import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def main():
    manifest = json.loads((ROOT / "customisations/shell/manifest.json").read_text())
    with tempfile.TemporaryDirectory(prefix="cq-") as directory:
        temporary = Path(directory)
        config = temporary / "config"
        shutil.copytree(ROOT / "quickshell/caelestia", config)
        (config / "original-shell.qml").write_bytes((config / "shell.qml").read_bytes())
        paths = [str(config / ("original-shell.qml" if entry["path"] == "shell.qml" else entry["path"]))
                 for entry in manifest["files"] if entry["path"].endswith(".qml")]
        runner = """import QtQuick
import Quickshell
import qs.services
import qs.custom
import qs.modules.lock
ShellRoot {
    settings.watchFiles: false
    Component.onCompleted: Qt.callLater(() => {
        let failures = 0;
        for (const path of PATHS) {
            const component = Qt.createComponent("file://" + path, Component.PreferSynchronous);
            if (component.status !== Component.Ready) {
                console.log("COMPILE_ERROR", path, component.errorString());
                failures++;
            }
        }
        console.log("COMPILE_RESULT", PATHS.length, failures);
        Qt.quit();
    })
}
""".replace("PATHS", json.dumps(paths))
        (config / "shell.qml").write_text(runner)
        runtime = temporary / "run"
        runtime.mkdir(mode=0o700)
        display = os.environ.get("WAYLAND_DISPLAY")
        if not display:
            raise SystemExit("Run this compilation check from a Wayland session.")
        if not display.startswith("/"):
            display = str(Path(os.environ["XDG_RUNTIME_DIR"]) / display)
        environment = {
            **os.environ,
            "HOME": str(temporary),
            "QT_QPA_PLATFORM": "wayland",
            "WAYLAND_DISPLAY": display,
            "XDG_RUNTIME_DIR": str(runtime),
            "XDG_CONFIG_HOME": str(temporary / "xdg"),
            "XDG_STATE_HOME": str(temporary / "state"),
            "XDG_CACHE_HOME": str(temporary / "cache"),
        }
        result = subprocess.run(["qs", "--no-color", "-p", str(config)],
                                env=environment, capture_output=True, text=True, timeout=25)
        output = result.stdout + result.stderr
        print(output)
        if result.returncode or f"COMPILE_RESULT {len(paths)} 0" not in output:
            raise SystemExit(1)


if __name__ == "__main__":
    main()
