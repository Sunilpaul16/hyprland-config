#!/usr/bin/env python3
"""Restore the configuration files; preserve replaced files in a dated backup."""
from datetime import datetime
from pathlib import Path
import argparse
import json
import shutil
import subprocess


def main():
    repo = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mode', choices=['custom', 'upstream'], default='custom')
    args = parser.parse_args()
    subprocess.run(['python3', str(repo / 'scripts/custom-shell'), 'prepare', '--mode', args.mode], check=True)
    runtime = repo / 'build/runtime'
    if not (runtime / 'lib/qt6/qml/Caelestia/State').is_dir():
        raise SystemExit('Build the matching plugins first: python3 scripts/custom-shell build')
    if not (runtime / 'upstream.json').is_file() or json.loads((runtime / 'upstream.json').read_text())['commit'] != json.loads((repo / 'customs/upstream.json').read_text())['commit']:
        raise SystemExit('The plugins do not match the pinned shell. Run python3 scripts/custom-shell build')
    if not (runtime / 'bin/qs').is_file() or not (runtime / 'python/caelestia/__main__.py').is_file():
        raise SystemExit('Stage the local runtime first with scripts/custom-shell build-quickshell and build-cli')
    source = repo / 'generated/files'
    home = Path.home()
    backup = home / '.local/state/caelestia-config-backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    state = home / '.local/state/caelestia'
    if state.is_dir():
        shutil.copytree(state, backup / '.local/state/caelestia', symlinks=True)

    def preserve(target):
        if target.exists() or target.is_symlink():
            saved = backup / target.relative_to(home)
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(target), str(saved))

    def replace_dir(source, target):
        preserve(target)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(source, target)

    def replace_file(source, target):
        preserve(target)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)

    for name in ('hypr', 'caelestia', 'kitty'):
        replace_dir(source / name, home / '.config' / name)
    for name in ('gtk-3.0', 'gtk-4.0'):
        replace_file(source / name / 'settings.ini', home / '.config' / name / 'settings.ini')
    replace_file(source / 'inputactions/config.yaml', home / '.config/inputactions/config.yaml')
    replace_dir(repo / 'generated/caelestia', home / '.config/quickshell/caelestia')
    replace_dir(source / 'quickshell/caelestia-cheatsheet', home / '.config/quickshell/caelestia-cheatsheet')
    replace_dir(runtime, home / '.local/share/caelestia-custom')
    replace_file(repo / 'scripts/caelestia-custom-shell', home / '.local/bin/caelestia-custom-shell')
    if (runtime / 'bin/qs').is_file():
        replace_file(repo / 'scripts/runtime-qs', home / '.local/bin/qs')
    if (runtime / 'bin/caelestia').is_file():
        replace_file(repo / 'scripts/runtime-caelestia', home / '.local/bin/caelestia')
    # Preserve any existing third-party Zsh installation and unrelated autostarts.
    for item in (source / 'zsh').iterdir():
        replace_file(item, home / '.config/zsh' / item.name)
    for item in (source / 'fontconfig/conf.d').iterdir():
        replace_file(item, home / '.config/fontconfig/conf.d' / item.name)
    replace_file(source / '.zshenv', home / '.zshenv')
    for item in (source / 'autostart').iterdir():
        replace_file(item, home / '.config/autostart' / item.name)
    replace_file(source / 'systemd/user/caelestia-wallpaper.service', home / '.config/systemd/user/caelestia-wallpaper.service')
    replace_file(source / 'systemd/user/xdg-desktop-portal-gtk.service.d/appearance.conf', home / '.config/systemd/user/xdg-desktop-portal-gtk.service.d/appearance.conf')
    subprocess.run(['python3', str(home / '.config/quickshell/caelestia-cheatsheet/refresh.py')], check=True)
    subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
    if args.mode == 'upstream' or not json.loads((repo / 'customs/features.json').read_text())['wallpapers']:
        subprocess.run(['systemctl', '--user', 'stop', 'caelestia-wallpaper.service'], check=True)
    print(f'Configuration restored. Backups: {backup}')
    print('See README.md for dependencies and first wallpaper setup. Log out and back in to apply everything.')


if __name__ == '__main__':
    main()
