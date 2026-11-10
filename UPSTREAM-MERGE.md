# Accepted upstream shell changes

The update branch accepts upstream shell commit
`5cbf60e7c6dbdd2b94faa5444435b8d9cac7bd46`. All four source conflicts are
resolved. The previous live-tested setup remains committed as `3197e0c` in the
clean `laptop-caelestia` working copy. This update has not been installed live.

## Archived and disconnected

| Custom implementation | Upstream replacement / resulting behaviour |
|---|---|
| mpvpaper bridge and wallpaper systemd unit | Native video playback inside the shell |
| Frame cache, generated-name cleanup and custom picker directory | Native wallpaper directory, image/video discovery and moving previews |
| Static/video toggle | Upstream Display wallpaper plus separate play/pause control |
| Custom game-mode wallpaper stop/restore and session flag | Upstream game-mode daemon and RuntimeState; automatic wallpaper pausing is no longer added |
| 20×20 sidebar click target, input region and hover/drag suppression | Upstream sidebar hover, drag and shortcut interactions |
| Old service loader | NightLight initialisation moved into the new shell startup block |

The previous source versions, baseline copies, old feature patches, standalone
wallpaper script/service and live-wallpaper test are preserved under
[`customisations/shell/archive/5cbf60e7/`](customisations/shell/archive/5cbf60e7/README.md).
The archived sources have no active runtime links. `resolution.json` records the
original conflicts and the decision to accept upstream in each case.

## Still connected

Personal app shortcuts and gestures, empty-scratchpad cycling/history, app and
scratchpad bar labels, manual Wi-Fi scanning, screenshot saving, Settings Escape,
cheatsheet and scheduled NightLight remain active in the source configuration.
The small wallpaper-picker shortcut remains, but it opens the native picker.
Super + Shift + T now uses `caelestia wallpaper -r`. Login no longer launches the
old wallpaper script, and the installer no longer installs its systemd unit.

The custom manifest/baseline now records the incoming upstream commit. Seventeen
active custom source files remain, grouped into seven feature patches. The
native wallpaper/game-mode/sidebar files match the incoming upstream source.

## Validation and activation status

- 22 Python tests pass, including isolated restore and feature-patch reconstruction.
  The old wallpaper-helper regression tests explicitly target the archived source.
- 35 Lua checks and 36 JavaScript checks pass for retained personal features.
- The source rebuild matches all 300 runtime files; archived-source preservation
  and link checks pass. All 285 runtime QML files pass syntax parsing. These
  checks are separate from executing the new shell.
- Matching native modules were built successfully at upstream `5cbf60e7`, and
  the video-capable CLI was built from `cd85cd7b`. Using those private builds,
  all 285 QML files compiled successfully without instantiating the live shell.
- The runtime launcher and startup/restart/cheatsheet wiring are prepared. The
  private build currently resides under `Projects/caelestia-runtime/5cbf60e7`;
  it has not been deployed to the launcher's default per-user runtime directory.

This is a saved preparation checkpoint. Live activation and interaction testing
of the new shell remain outstanding. No system packages or running desktop were
changed by these builds. The accepted update and archived customisations are
saved on `caelestia-shell-update-20261109`; no push was performed. Build artifacts
and the separate upstream source clones are outside this dotfiles repository.
