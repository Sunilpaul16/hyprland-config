# Personal Caelestia configuration

All personal shell sources are collected here and connected through relative
links at their original repository paths. The installer copies the real files
into `~/.config`, preserving the existing runtime paths.

- [`standalone/`](standalone/README.md): scripts, Lua overrides, shell preferences,
  monitor preferences, cheatsheet, NightLight service and supporting configuration.
- [`shell/`](shell/README.md): custom QML/JavaScript components, integration hooks,
  feature patches and upstream baseline information.

Start with `shell/patches/` when comparing an upstream feature with our version.
The patches are grouped into wallpapers, scratchpads/bar, sidebar, network,
night light, settings, screenshots and shell settings. Their implementation
sources and upstream integration points are listed in `shell/manifest.json`.

This organisation still targets upstream v2.5.0. It does not install the latest
shell or automatically retire personal features when upstream adds equivalents.

The reorganised configuration was activated on the laptop on 2026-11-09.
See the [live test report](LIVE-TEST-REPORT.md) for results, backup location and
remaining session issues.
