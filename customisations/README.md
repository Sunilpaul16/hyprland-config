# Personal Caelestia configuration

All personal shell sources are collected here and connected through relative
links at their original repository paths. The installer copies the real files
into `~/.config`, preserving the existing runtime paths.

- [`standalone/`](standalone/README.md): scripts, Lua overrides, shell preferences,
  monitor preferences, cheatsheet, NightLight service and supporting configuration.
- [`shell/`](shell/README.md): custom QML/JavaScript components, integration hooks,
  feature patches and upstream baseline information.

Start with `shell/patches/` when comparing an upstream feature with our version.
The active patches cover the wallpaper shortcut, scratchpads/bar, network,
night light, settings, screenshots and shell settings. Old wallpaper and sidebar
patches are archived. Their implementation
sources and upstream integration points are listed in `shell/manifest.json`.

The source now targets upstream `5cbf60e7`. Overlapping personal wallpaper,
game-mode and sidebar implementations are preserved in the archive with their
links removed. See [`../UPSTREAM-MERGE.md`](../UPSTREAM-MERGE.md) for accepted
changes and runtime requirements. The historical live report below refers to
the previous configuration, which remains the running desktop.

The previous reorganised configuration was activated on 2026-11-09.
See the [historical live test report](LIVE-TEST-REPORT.md) for that deployment.
