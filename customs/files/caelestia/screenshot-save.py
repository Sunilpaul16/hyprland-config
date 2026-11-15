#!/usr/bin/env python3
"""Save each capture before copying it or opening the editor."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import subprocess
import tempfile


def save_capture(data):
    folder = Path.home() / "Pictures" / "Screenshots"
    folder.mkdir(parents=True, exist_ok=True)
    # Exclusive creation prevents simultaneous captures overwriting each other.
    with tempfile.NamedTemporaryFile(
        prefix=datetime.now().strftime("screenshot-%Y%m%d-%H%M%S-"),
        suffix=".png", dir=folder, delete=False,
    ) as output:
        path = Path(output.name)
        try:
            output.write(data)
        except BaseException:
            path.unlink(missing_ok=True)
            raise
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", type=Path)
    parser.add_argument("--edit", action="store_true")
    args = parser.parse_args()
    if args.file:
        data = args.file.read_bytes()
    else:
        monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"]))
        monitor = next(m for m in monitors if m["focused"])
        data = subprocess.check_output(["grim", "-o", monitor["name"], "-"])
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("Capture did not produce a PNG")
    path = save_capture(data)
    # Clipboard/notification failures must never prevent saving the capture.
    for command, options in (
        (["wl-copy", "--type", "image/png"], {"input": data}),
        (["notify-send", "-a", "screenshot", "Screenshot saved", str(path)], {}),
    ):
        try:
            subprocess.run(command, check=False, **options)
        except OSError:
            pass
    if args.edit:
        subprocess.Popen(["swappy", "-f", str(path), "-o", str(path)], start_new_session=True)


if __name__ == "__main__":
    main()
