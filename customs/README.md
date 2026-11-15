# Personal configuration

`files/` contains the personal Hyprland, Caelestia, terminal, GTK, gesture and
service files. It includes the installed desktop adaptations and the newer
laptop branch shortcuts and scratchpad gestures. `defaults/` seeds lock colours.
`patches/` contains focused diffs against the pristine shell snapshot.
`features.json` selects which shell patches `scripts/custom-shell prepare` applies.

| Feature | Default | Purpose |
|---|---|---|
| scratchpads | On | Scratchpad history, creation/cycling, app names and scratchpad labels |
| desktop-ui | On | Compact settings windows, Escape to close, screenshot saving, secondary-monitor lock background and wallpaper-launcher IPC |
| manual-wifi | On | Scan buttons and cached network lists instead of periodic rescans |
| night-light | On | Scheduled Hyprsunset status and settings toggle |
| wallpapers | Off | Legacy mpvpaper bridge, thumbnails and game-mode playback integration |
| sidebar-corner | On | Legacy top-right click target and desktop hover behaviour |

The disabled wallpaper patch is ported to the current runtime-state API, but
native upstream playback is preferred. The disabled sidebar patch overrides
upstream sidebar interactions; leave it disabled to use upstream's improvements.
Legacy wallpaper mode needs desktop-ui for its launcher IPC.

When adding a custom shell edit, change a temporary copy of the pristine file
and put its unified diff in the relevant patch. Never edit the vendored source
or generated files as the permanent location of a personal change. Standalone
custom scripts/settings belong under `files/`.

All shell patches can be bypassed with the upstream profile. Disabling an
individual shell patch does not reset unrelated personal application settings.
Generated shortcuts use upstream wallpaper commands when the legacy bridge is
disabled, and fall back to the standard special workspace when the scratchpad
patch is disabled. Monitor geometry remains in both profiles for usability.
