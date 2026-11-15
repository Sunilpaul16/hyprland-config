#!/usr/bin/env python3
"""Add modern libadwaita colour variables after Caelestia generates GTK themes."""
import json
import os
from pathlib import Path
import re

home = Path.home()
state = Path(os.environ.get('XDG_STATE_HOME', home / '.local/state')) / 'caelestia'
config = Path(os.environ.get('XDG_CONFIG_HOME', home / '.config'))
raw = os.environ.get('SCHEME_COLOURS')
colours = json.loads(raw) if raw else json.loads((state / 'scheme.json').read_text())['colours']
roles = {
    'accent-color': 'primary', 'accent-bg-color': 'primary', 'accent-fg-color': 'onPrimary',
    'window-bg-color': 'background', 'window-fg-color': 'onBackground',
    'view-bg-color': 'surface', 'view-fg-color': 'onSurface',
    'headerbar-bg-color': 'surfaceDim', 'headerbar-fg-color': 'onSurface',
    'headerbar-backdrop-color': 'surfaceDim', 'headerbar-border-color': 'outlineVariant',
    'sidebar-bg-color': 'surfaceContainerLow', 'sidebar-fg-color': 'onSurface',
    'sidebar-backdrop-color': 'surfaceContainerLow',
    'secondary-sidebar-bg-color': 'surfaceContainer', 'secondary-sidebar-fg-color': 'onSurface',
    'secondary-sidebar-backdrop-color': 'surfaceContainer',
    'popover-bg-color': 'surfaceContainer', 'popover-fg-color': 'onSurface',
    'dialog-bg-color': 'surfaceContainerHigh', 'dialog-fg-color': 'onSurface',
    'card-bg-color': 'surfaceContainerLow', 'card-fg-color': 'onSurface',
}
for role in roles.values():
    if not re.fullmatch(r'[0-9a-fA-F]{6}', colours[role]):
        raise ValueError(f'Invalid scheme colour: {role}')
start = '/* Caelestia modern GTK colours: begin */'
end = '/* Caelestia modern GTK colours: end */'
p = config / 'gtk-4.0/gtk.css'
text = p.read_text() if p.exists() else ''
text = re.sub(re.escape(start) + r'.*?' + re.escape(end) + r'\n?', '', text, flags=re.S)
text = text.replace('@define-color theme_selected_fg_color @primary;', '@define-color theme_selected_fg_color @accent_fg_color;')
block = ':root {\n' + ''.join(f'  --{name}: #{colours[role]};\n' for name, role in roles.items()) + '}\n'
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(text.rstrip() + '\n\n' + start + '\n' + block + end + '\n')
