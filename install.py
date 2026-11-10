#!/usr/bin/env python3
"""Restore the configuration files; preserve replaced files in a dated backup."""
from datetime import datetime
import json
from pathlib import Path
import shutil
import subprocess


def main():
    repo = Path(__file__).resolve().parent
    if (repo / 'customisations/shell/pending-update.json').exists():
        raise SystemExit('Upstream shell merge needs review. See UPSTREAM-MERGE.md before installing.')
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
    replace_file(repo / 'bin/caelestia', home / '.local/bin/caelestia')
    for name in ('gtk-3.0', 'gtk-4.0'):
        replace_file(repo / name / 'settings.ini', home / '.config' / name / 'settings.ini')
    replace_file(repo / 'inputactions/config.yaml', home / '.config/inputactions/config.yaml')
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
    legacy_wallpaper_unit = home / '.config/systemd/user/caelestia-wallpaper.service'
    if legacy_wallpaper_unit.exists() or legacy_wallpaper_unit.is_symlink():
        subprocess.run(['systemctl', '--user', 'stop', 'caelestia-wallpaper.service'], check=True)
        preserve(legacy_wallpaper_unit)
    replace_file(repo / 'systemd/user/xdg-desktop-portal-gtk.service.d/appearance.conf', home / '.config/systemd/user/xdg-desktop-portal-gtk.service.d/appearance.conf')
    subprocess.run(['python3', str(home / '.config/quickshell/caelestia-cheatsheet/refresh.py')], check=True)
    subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
    custom = json.loads((repo / 'customisations/standalone/links.json').read_text())
    for unit in custom.get('service_masks', []):
        subprocess.run(['systemctl', '--user', 'mask', '--now', unit], check=True)
    print(f'Configuration restored. Backups: {backup}')
    print('See README.md for dependencies and first wallpaper setup. Log out and back in to apply everything.')


if __name__ == '__main__':
    main()
