#!/usr/bin/env python3
"""Load the Files gesture plugin only into its matching Hyprland build."""
import json
from pathlib import Path
import subprocess
import sys
import time


def notify_when_shell_ready(message):
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        try:
            instances = subprocess.run(['qs', '-c', 'caelestia', 'list', '-j'],
                                       capture_output=True, text=True, timeout=1)
            pids = {instance['pid'] for instance in json.loads(instances.stdout)} if instances.returncode == 0 else set()
            owner = subprocess.run([
                'busctl', '--user', 'call', 'org.freedesktop.DBus',
                '/org/freedesktop/DBus', 'org.freedesktop.DBus',
                'GetConnectionUnixProcessID', 's', 'org.freedesktop.Notifications',
            ], capture_output=True, text=True, timeout=1)
            fields = owner.stdout.split()
            if owner.returncode == 0 and len(fields) == 2 and fields[0] == 'u' and int(fields[1]) in pids:
                subprocess.run(['notify-send', 'Files gestures', message], check=False)
                return
        except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired):
            pass
        time.sleep(0.2)
    print('Files gestures: ' + message, file=sys.stderr)


def main():
    metadata = Path.home() / ".local/share/inputactions/hyprland/build.json"
    if not metadata.exists():
        return
    build = json.loads(metadata.read_text())
    running = json.loads(subprocess.check_output(["hyprctl", "version", "-j"]))
    if running.get("abiHash") != build["abiHash"]:
        notify_when_shell_ready("Hyprland changed. Rebuild InputActions using scripts/build-files-gestures.py in your laptop config.")
        return
    loaded = subprocess.check_output(["hyprctl", "plugin", "list"], text=True)
    if "InputActions" not in loaded:
        subprocess.run(["hyprctl", "plugin", "load", build["plugin"]], check=True)


if __name__ == "__main__":
    main()
