from pathlib import Path
import re,json
home=Path.home(); base=home/'.config/caelestia'
variables=dict(re.findall(r'M\.(\w+)\s*=\s*"([^"]*)"',(base/'my-shortcut-vars.lua').read_text()))
special_keys = {
    'SUPER + SUPER_R': ('Right Win', 'Show / hide last scratchpad (on press)'),
    'ALT + ALT_R': ('AltGr', 'Move active window into / out of scratchpad (on press)'),
    'SUPER + SHIFT + F23': ('Copilot', 'Show / hide last scratchpad'),
    'SUPER + SHIFT + MOD5 + F23': ('AltGr + Copilot', 'Move active window into / out of scratchpad'),
}
groups={}
for line in (base/'my-shortcuts.lua').read_text().splitlines():
    m=re.match(r'hl\.bind\((?:v\.(\w+)|"([^"]+)").*description = "([^"]+)"',line)
    if not m: continue
    if m[1] in ('kbBrightnessUp', 'kbBrightnessDown'): continue
    key=variables.get(m[1],m[2] or '')
    category,_,label=m[3].partition(':')
    if '<N>' in label: continue
    if key in special_keys:
        key, label = special_keys[key]
    else:
        key=key.replace('SUPER','Super').replace('MOD3','Right Win').replace('SHIFT','Shift').replace('CTRL','Ctrl').replace('ALT','Alt').replace('Grave','`').replace('Slash','/').replace('XF86','').replace('mouse:272','LMB drag').replace('mouse:273','RMB drag')
    groups.setdefault(category,[]).append({'key':key,'label':label.strip()})
groups.setdefault('Workspace',[]).extend([{'key':'Super + 1–0','label':'Switch workspace 1–10'},{'key':'Super + Shift + 1–0','label':'Move window to workspace'}])
corner = home/'.config/quickshell/caelestia/modules/drawers/ContentWindow.qml'
if corner.is_file() and 'onClicked: root.screenState.sidebar = !root.screenState.sidebar' in corner.read_text():
    groups.setdefault('System', []).append({'key':'Top-right corner click','label':'Show / hide sidebar (outside fullscreen)'})
groups['Kitty']=[{'key':'Ctrl + = / −','label':'Increase / decrease font'},{'key':'Ctrl + 0','label':'Reset font size'},{'key':'Ctrl + C / V','label':'Copy or interrupt / paste'},{'key':'Ctrl + F','label':'Search terminal'}]
# Active means configured; it is not a hardware or application test.
for rows in groups.values():
    for row in rows:
        row['active'] = True
# Hide these sections from the cheatsheet; the actual bindings remain configured.
groups.pop('Media', None)
groups.pop('Record', None)
groups.pop('Help', None)
groups.setdefault('System', []).extend(groups.pop('Shell', []))
if 'Window' in groups:
    groups['Window'] = groups['Window'][:8]
(home/'.config/quickshell/caelestia-cheatsheet/data.json').write_text(json.dumps([{'title':k,'rows':v} for k,v in groups.items()]))
