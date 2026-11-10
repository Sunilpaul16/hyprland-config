# Personal Caelestia configuration

The [top-right sidebar click target](SIDEBAR-CORNER.md) is restored on the new
shell; hover-to-open is disabled while native drag/shortcut controls remain.

The [notification ownership fix](NOTIFICATION-FIX.md) restores Caelestia's popups
and history and prevents Dunst from taking over at login.

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

The source and live laptop now use upstream `5cbf60e7`. Overlapping personal wallpaper,
game-mode and sidebar implementations are preserved in the archive with their
links removed. See [`../UPSTREAM-MERGE.md`](../UPSTREAM-MERGE.md) for accepted
changes and runtime requirements. See the [native upgrade report](NATIVE-UPGRADE-REPORT.md)
for the active runtime, test results and rollback backup. The historical report
below refers to the previous configuration.

The previous reorganised configuration was activated on 2026-11-09.
See the [historical live test report](LIVE-TEST-REPORT.md) for that deployment.
