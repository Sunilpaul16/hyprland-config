import json
import os
from pathlib import Path
import subprocess
import time


HOME = Path.home()
STATE = HOME / ".local/state/caelestia/state.json"
LAUNCHER = HOME / ".config/caelestia/runtime.py"


def output(*args):
    return subprocess.check_output(args, text=True, timeout=20).strip()


def ipc(target, action):
    return output("qs", "-c", "caelestia", "ipc", "call", target, action)


def wait_for(check, description):
    for _ in range(80):
        if check():
            return
        time.sleep(0.1)
    raise AssertionError(description)


def pid():
    return json.loads(output("qs", "-c", "caelestia", "list", "-j"))[0]["pid"]


def video_open(source):
    for descriptor in (Path("/proc") / str(pid()) / "fd").iterdir():
        try:
            if Path(os.readlink(descriptor)) == source:
                return True
        except FileNotFoundError:
            pass
    return False


def restart(state):
    subprocess.run(["qs", "-c", "caelestia", "kill"], check=True, capture_output=True)
    wait_for(lambda: subprocess.run(["qs", "-c", "caelestia", "ipc", "show"],
                                   capture_output=True).returncode != 0, "Old shell did not exit")
    STATE.write_text(state)
    subprocess.run(["python3", str(LAUNCHER), "caelestia", "shell", "-d"], check=True)
    wait_for(lambda: subprocess.run(["qs", "-c", "caelestia", "ipc", "call", "gameMode", "isEnabled"],
                                   capture_output=True).returncode == 0, "Shell did not restart")


def main():
    original = STATE.read_text()
    original_game = ipc("gameMode", "isEnabled").lower() == "true"
    source = Path(ipc("wallpaper", "get"))
    if source.suffix.lower() not in {".mp4", ".mkv", ".webm", ".mov", ".avi"}:
        raise SystemExit("Select a native video wallpaper before running this test.")
    try:
        state = json.loads(original)
        state["wallpaperPlaying"] = True
        playing = json.dumps(state, indent=2) + "\n"
        restart(playing)
        wait_for(lambda: video_open(source), "Native player did not open the video")
        print("PASS native video player opened the selected wallpaper", flush=True)
        maps = (Path("/proc") / str(pid()) / "maps").read_text()
        expected = str(HOME / ".local/share/caelestia/runtime/5cbf60e7")
        assert expected in maps
        assert "/usr/lib/qt6/qml/Caelestia/" not in maps
        print("PASS shell uses private Caelestia modules without mixing system modules", flush=True)
        ipc("gameMode", "enable")
        wait_for(lambda: ipc("gameMode", "isEnabled").lower() == "true", "Game mode did not enable")
        assert video_open(source), "Upstream game mode unexpectedly stopped native playback"
        restart(playing)
        assert ipc("gameMode", "isEnabled").lower() == "true"
        wait_for(lambda: video_open(source), "Native video did not resume after restart")
        print("PASS upstream game mode survives restart and leaves wallpaper playback independent", flush=True)
        ipc("gameMode", "disable")
        state["wallpaperPlaying"] = False
        restart(json.dumps(state, indent=2) + "\n")
        wait_for(lambda: not video_open(source), "Paused video did not release the player")
        time.sleep(1)
        assert not video_open(source)
        print("PASS paused wallpaper releases the native video file", flush=True)
        assert ipc("wallpaper", "get") == str(source)
        assert subprocess.run(["pgrep", "-x", "mpvpaper"], capture_output=True).returncode == 1
        print("PASS selected wallpaper retained and no mpvpaper process running", flush=True)
    finally:
        if original_game:
            ipc("gameMode", "enable")
        else:
            ipc("gameMode", "disable")
        restart(original)
        assert ipc("gameMode", "isEnabled").lower() == str(original_game).lower()
        print("Original native playback and game-mode preferences restored", flush=True)


if __name__ == "__main__":
    main()
