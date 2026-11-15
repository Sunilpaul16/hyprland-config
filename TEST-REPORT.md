# Verification — 2026-11-15

- Latest pinned shell snapshot matches all 543 upstream source files.
- Matching Caelestia C++ plugins built successfully against installed Qt.
- Quickshell 0.3.2 rebuilt locally against Qt 6.12.0; system package unchanged.
- Current Caelestia CLI staged locally for native video selection.
- Compile-only Wayland preflight loaded the full shell type graph and exited successfully.
- 26 Python tests passed, including profile composition, conflict preservation and isolated restore.
- 35 Lua shortcut/gesture checks passed.
- 36 JavaScript behaviour checks passed using Qt QJSEngine with a temporary Node module shim and equivalent object-spread syntax adaptation. Node is not installed.
- Changed QML files parsed successfully; whitespace checks passed.
- Installed custom profile and restarted the shell successfully.
- Exactly one live shell instance uses the local rebuilt binary and matching local Caelestia plugins.
- Hyprland reload succeeded and reports no configuration errors.
- Background surfaces exist on both desktop monitors.
- Fuji/Torii video selected with the upstream CLI; changing wallpaper pixels confirmed playback.
- Legacy mpvpaper service is inactive.

The live startup log contains two shader-version compatibility warnings, and
switching from the old thumbnail to video produced an image-analysis warning.
Native video playback and the visible bar render correctly; every transition
style and popup has not been exercised. Browser policy theme writes under
`/etc` were denied; no permissions were elevated for these optional theme targets.

The activation backup location and source revision are recorded locally in
`~/.local/state/hyprland-config/caelestia-activation.json`.
