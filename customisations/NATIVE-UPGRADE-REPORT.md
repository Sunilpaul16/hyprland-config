# Native shell upgrade — 2026-11-10

The accepted upstream shell is now running on the laptop. Only the shell,
required startup/shortcut routing, wallpaper pointers and retired wallpaper
service were changed. The full dotfiles installer was not run. Shell and monitor
preferences remained byte-for-byte unchanged; terminal and application theme
settings were not replaced or regenerated.

## Runtime

- Shell source/native modules: `5cbf60e7c6dbdd2b94faa5444435b8d9cac7bd46`.
- CLI source: `cd85cd7b543bee784eaaf0bfb9ae2bd39d136ffb`, installed as
  `1.1.4.dev52+gcd85cd7b5` in the private runtime.
- Private runtime: `~/.local/share/caelestia/runtime/5cbf60e7/`.
- User command wrapper: `~/.local/bin/caelestia`.
- Startup/restart environment: `~/.config/caelestia/runtime.py` and `runtime.json`.

The existing system packages were not replaced. The running process was checked
to load the private Caelestia modules without mixing the older system modules.
Use `caelestia shell -d` or the configured restart shortcut. Launching `qs`
directly from an unrelated terminal bypasses this runtime environment; use
`python3 ~/.config/caelestia/runtime.py qs ...` when starting a configuration
directly. Ordinary `qs ... ipc ...` calls to running instances need no wrapper.

The private runtime and upstream build/source directories are outside this Git
repository. Keep or rebuild that runtime when restoring the dotfiles; the
configuration installer does not compile or install native libraries.

## Wallpaper and retained features

The original selected video was migrated from the legacy helper's state to
native wallpaper pointers and thumbnails, without applying a new colour scheme.
Playback is paused because the previous setup used a static wallpaper. Use the
utilities wallpaper play/pause toggle to animate it. Display wallpaper now
shows/hides the background; it is not the previous static/video switch.

The old mpvpaper helper and service are absent from the live configuration.
Their implementations remain in the source archive. Native game mode does not
automatically pause wallpapers; playback remains an independent upstream control.

Personal shortcuts, gestures, scratchpad controller/bar labels, manual Wi-Fi
scanning, screenshot saving, Settings Escape, cheatsheet and NightLight remain
connected. Startup, restart and random-wallpaper shortcuts use the private CLI.

## Verification

- All 300 live shell files match the accepted source configuration.
- All 285 QML files compiled against the relocated private runtime.
- 22 Python tests, 35 Lua checks and 36 JavaScript checks passed.
- Native playback opened the selected video. Pausing released its file, and
  there was no mpvpaper process.
- Game mode survived a shell restart; native wallpaper playback remained
  independent, as upstream implements it.
- Sidebar open/close, populated native picker, scratchpad next/previous/hide/
  reopen, bar preference round trip, NightLight, Settings Escape and standalone
  cheatsheet live checks passed.
- Original tested playback/game-mode/panel/NightLight preferences and focus
  were restored. The final Hyprland configuration reported no errors, and the
  final shell log contained no ReferenceError, TypeError or startup failure.

`python3 tests/live_native_wallpaper.py` repeats the native player/state tests.
It temporarily changes playback/game mode and restarts the shell, restoring the
original settings afterwards. Run it with access to the logged-in session.

## Backup and remaining limits

The previous shell, replaced files, wallpaper state, preferences and rollback
metadata were saved under:

```text
~/.local/state/caelestia-config-backups/native-upgrade-20261110-111953-637307/
```

`rollback.json` records every replaced/previously absent target and its backup.
The older stable working copy and system native modules remain available. This
deployment did not commit or push the new test/report files.

The subsequent [notification fix](NOTIFICATION-FIX.md) stopped/masked Dunst and
restored Caelestia popup/history ownership, including after a shell restart.
The optional InputActions plugin still needs rebuilding for the current
Hyprland ABI. Qt also probed an unavailable NVIDIA VDPAU
backend during video tests; the native video opened successfully despite that
warning. Hardware decoding efficiency was not measured. Physical key/touchpad
delivery, reboot/login, lock/authentication and suspend/resume were not tested.
