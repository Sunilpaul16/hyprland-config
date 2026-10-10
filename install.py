#!/usr/bin/env python3
"""Restore the configuration files; preserve replaced files in a dated backup."""
from datetime import datetime
from pathlib import Path
import shutil
import subprocess


def main():
    repo = Path(__file__).resolve().parent
    home = Path.home()
    backup = home / '.local/state/caelestia-config-backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')

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
        replace_dir(repo / name, home / '.config' / name)
    for name in ('caelestia', 'caelestia-cheatsheet'):
        replace_dir(repo / 'quickshell' / name, home / '.config/quickshell' / name)
    # Preserve any existing third-party Zsh installation and unrelated autostarts.
    for source in (repo / 'zsh').iterdir():
        replace_file(source, home / '.config/zsh' / source.name)
    for source in (repo / 'fontconfig/conf.d').iterdir():
        replace_file(source, home / '.config/fontconfig/conf.d' / source.name)
    replace_file(repo / '.zshenv', home / '.zshenv')
    for source in (repo / 'autostart').iterdir():
        replace_file(source, home / '.config/autostart' / source.name)
    replace_file(repo / 'systemd/user/caelestia-wallpaper.service', home / '.config/systemd/user/caelestia-wallpaper.service')
    subprocess.run(['python3', str(home / '.config/quickshell/caelestia-cheatsheet/refresh.py')], check=True)
    subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
    print(f'Configuration restored. Backups: {backup}')
    print('See README.md for dependencies and first wallpaper setup. Log out and back in to apply everything.')


if __name__ == '__main__':
    main()
