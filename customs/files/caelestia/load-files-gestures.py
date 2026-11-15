#!/usr/bin/env python3
"""Load the Files gesture plugin only into its matching Hyprland build."""
import json
from pathlib import Path
import subprocess


def main():
    metadata = Path.home() / ".local/share/inputactions/hyprland/build.json"
    if not metadata.exists():
        return
    build = json.loads(metadata.read_text())
    running = json.loads(subprocess.check_output(["hyprctl", "version", "-j"]))
    if running.get("abiHash") != build["abiHash"]:
        subprocess.run(["notify-send", "Files gestures", "Hyprland changed. Rebuild InputActions using scripts/build-files-gestures.py in your laptop config."])
        return
    loaded = subprocess.check_output(["hyprctl", "plugin", "list"], text=True)
    if "InputActions" not in loaded:
        subprocess.run(["hyprctl", "plugin", "load", build["plugin"]], check=True)


if __name__ == "__main__":
    main()
