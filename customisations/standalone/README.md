# Standalone personal features

These are the actual custom source files, moved out of the upstream/configuration
directories. Edit them here. Their original repository paths are relative
symbolic links to these files, so existing imports, commands and tests keep
working without copies that can drift apart. `links.json` lists every moved file.

| Feature | Source in this folder | Existing connection |
|---|---|---|
| Wallpapers | Native upstream implementation | Personal shortcuts open the native picker or run `caelestia wallpaper -r`; old helper/service are archived |
| Screenshot saving | `caelestia/screenshot-save.py` | Personal shortcuts and the area picker call the helper |
| Bar toggle | `caelestia/toggle-bar.py` | Personal shortcut calls the helper |
| Personal keyboard bindings | `caelestia/my-shortcuts.lua`, `caelestia/my-shortcut-vars.lua` | Loaded by `hypr-user.lua` |
| Personal gestures | `caelestia/my-gestures.lua` | Loaded by `hypr-user.lua` |
| Laptop settings and startup | `caelestia/hypr-user.lua`, `caelestia/hypr-vars.lua` | Caelestia's existing user override hooks |
| Files gestures and media tap | `caelestia/load-files-gestures.py`, `inputactions/` | Startup loader and InputActions configuration |
| Shortcut cheatsheet | `quickshell/caelestia-cheatsheet/` | Runs as a separate Quickshell configuration |
| Scheduled night light | `quickshell/caelestia/services/NightLight.qml`, `hypr/hyprsunset.conf` | Service loader and Settings call the service; startup starts Hyprsunset |
| Shell and monitor preferences | `caelestia/shell.json`, `caelestia/monitors/` | Caelestia's normal configuration loading |

The existing installer follows the repository links and installs ordinary files
at the same `~/.config` paths as before. The installed configuration does not
depend on the location of this checkout. This move does not install anything or
change the running desktop. To use future edits, restore the reviewed files
through the installer or copy the relevant files to the installed configuration.
The touchpad udev rule still requires manual administrator installation into
`/etc/udev/rules.d/`, as documented in the main README; the installer does not
install it into `~/.config` or change system permissions.

The custom QML/JavaScript implementations and their remaining upstream integration
hooks live in [`../shell/`](../shell/README.md). NightLight's existing service path
links directly to its standalone source here. The source update is accepted; activating it with matching native modules and
a video-capable CLI remains a separate step.
