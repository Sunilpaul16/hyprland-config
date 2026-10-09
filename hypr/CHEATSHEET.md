# Laptop shortcut cheatsheet

Super + / toggles the graphical cheatsheet. Press Esc or use the close button to close. This Markdown file is also available as a reference.

Super = Windows key. Brightness uses the physical keys.

## Active Hyprland shortcuts

| Keys | Action |
|---|---|
| SUPER + Grave | App: terminal |
| SUPER + Q | Window: close |
| SUPER + E | App: file manager |
| SUPER + ALT + Space | Window: toggle floating |
| SUPER + ALT + P | Window: toggle pseudotile |
| SUPER + J | Window: toggle split direction |
| SUPER + F | Window: Fullscreen |
| SUPER + P | Window: Pin |
| SUPER + W | App: browser |
| SUPER + L | System: lock screen |
| SUPER + CTRL + ALT + R | System: reload Hyprland config |
| SUPER + C | App: code editor |
| SUPER + left | Window: focus left |
| SUPER + right | Window: focus right |
| SUPER + up | Window: focus up |
| SUPER + down | Window: focus down |
| SUPER + SHIFT + F23 | Workspace: Copilot toggle scratchpad |
| SUPER + S | Workspace: toggle scratchpad |
| SUPER + ALT + S | Workspace: move window to scratchpad |
| SUPER + mouse_down | Workspace: next |
| SUPER + mouse_up | Workspace: previous |
| SUPER + mouse:272 | Window: drag with mouse |
| SUPER + mouse:273 | Window: resize with mouse |
| XF86AudioRaiseVolume | Media: volume up |
| XF86AudioLowerVolume | Media: volume down |
| XF86AudioMute | Media: mute |
| XF86AudioMicMute | Media: mic mute |
| XF86AudioNext | Media: next track |
| XF86AudioPause | Media: play/pause |
| XF86AudioPlay | Media: play/pause |
| XF86AudioPrev | Media: previous track |
| SUPER + Minus | Screen: zoom out |
| SUPER + Equal | Screen: zoom in |
| SUPER + 1–9 / 0 | Switch to workspace 1–9 / 10 |
| SUPER + SHIFT + 1–9 / 0 | Move window to workspace 1–9 / 10 |

## Touchpad

- Three fingers horizontally: switch workspace.
- Three fingers up: open the magic scratchpad (same as Super + S).
- Three fingers down: toggle the active special workspace, or magic scratchpad.
- Four fingers up: enter fullscreen.
- Four fingers down: leave fullscreen.
- Four fingers left/right: next/previous populated scratchpad.
- Bar highlight uses the theme primary colour for normal workspaces and tertiary colour for scratchpads.
- Natural scrolling, scroll factor 0.8, disable while typing.

## Kitty

- Ctrl + Plus / Equal: increase text size.
- Ctrl + Minus: decrease text size.
- Ctrl + 0: reset text size.
- Ctrl + C: copy selection, otherwise interrupt.
- Ctrl + V: paste.
- Ctrl + F: search.

## Caelestia shortcuts

| Keys | Action |
|---|---|
| SUPER + Space | Launcher: apps |
| SUPER + V | Launcher: clipboard history |
| SUPER + CTRL + R | System: restart Caelestia |
| SUPER + D | Launcher: dashboard |
| SUPER + I | Launcher: Caelestia settings |
| SUPER + B | Shell: toggle bar |
| SUPER + T | Launcher: open launcher; type >wallpaper |
| SUPER + SHIFT + T | Launcher: random wallpaper |
| Print | Screenshot: fullscreen |
| SHIFT + Print | Screenshot: region |
| SUPER + ALT + R | Record: region (toggle) |
| SUPER + ALT + SHIFT + R | Record: fullscreen (toggle) |

## Unassigned shortcuts

Super + Tab, Super + O, Super + Shift + O, and Super + Shift + Print are unassigned. Old shell bindings have been removed.

## Caelestia commands

Run in a terminal:

```sh
caelestia shell -s
qs -c caelestia ipc call drawers toggle launcher
qs -c caelestia ipc call drawers toggle dashboard
qs -c caelestia ipc call drawers toggle utilities
qs -c caelestia ipc call nexus open
```

## Retained settings

- eDP-1: 2560x1600 at 60 Hz, scale 1.25.
- Kitty, Nautilus, Chrome and VS Code app bindings.
- Laptop window/workspace/audio/media bindings; brightness keys now use Caelestia (5% steps).
- Zsh/Oh My Zsh/Powerlevel10k and Kitty config.
- Caelestia handles locking and idle; old Hyprlock/Hypridle configs removed.
- Hyprland appearance, animations, and window rules now use Caelestia upstream defaults.
- Personal shortcuts: ~/.config/caelestia/my-shortcuts.lua.
- Shortcut variables: ~/.config/caelestia/my-shortcut-vars.lua.
- Laptop overrides: ~/.config/caelestia/hypr-user.lua.
- Old Quickshell/Matugen wallpaper/theme system has not been installed.
- Caelestia uses its own default appearance and idle settings.


Super + Shift + S: fullscreen screenshot. Super + Ctrl + Shift + S: region screenshot.



Copilot: toggle magic scratchpad. AltGr + Copilot: move the focused app into magic, or back to the normal workspace when it is in a scratchpad.
