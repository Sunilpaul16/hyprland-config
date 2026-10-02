#!/usr/bin/env python3
"""Apply the shell's font preferences to GTK and qt5ct/qt6ct applications."""
import configparser
import os
from pathlib import Path
import subprocess
import sys


def apply(interface, monospace, size, config_root):
    size = int(size)
    if not 8 <= size <= 20 or any(c in interface + monospace for c in '\n\r,'):
        raise ValueError('Invalid font preferences')
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', 'font-name', f'{interface} {size}'], check=True)
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', 'monospace-font-name', f'{monospace} {size}'], check=True)
    for name in ('gtk-3.0', 'gtk-4.0', 'qt5ct', 'qt6ct'):
        path = config_root / name / ('settings.ini' if name.startswith('gtk') else f'{name}.conf')
        config = configparser.ConfigParser(interpolation=None, strict=False)
        config.optionxform = str
        if path.exists():
            config.read(path)
        section = 'Settings' if name.startswith('gtk') else 'Fonts'
        if not config.has_section(section):
            config.add_section(section)
        if name.startswith('gtk'):
            config[section]['gtk-font-name'] = f'{interface} {size}'
        else:
            # The 10-field QFont format uses the legacy 0–99 weight scale,
            # including when read by Qt 6: 50 maps to normal weight 400.
            weight = 50
            config[section]['general'] = f'"{interface},{size},-1,5,{weight},0,0,0,0,0"'
            config[section]['fixed'] = f'"{monospace},{size},-1,5,{weight},0,0,0,0,0"'
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_name(path.name + '.font-tmp')
        with temporary.open('w') as output:
            config.write(output, space_around_delimiters=False)
        temporary.replace(path)


if __name__ == '__main__':
    apply(*sys.argv[1:4], Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))))
