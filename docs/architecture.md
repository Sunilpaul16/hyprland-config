# Configuration layout

- `quickshell/caelestia/`: exact upstream Git archive, including matching C++ plugins.
- `customs/upstream.json`: pinned upstream revision/version and original comparison base.
- `customs/files/`: personal configuration, using desktop hardware and newer laptop shortcuts.
- `customs/patches/` and `features.json`: optional upstream changes, applied only to generated copies.
- `scripts/custom-shell`: transactional source update and profile composition; local plugin build.
- `generated/`: ignored composed shell, installable files and profile metadata.
- `build/runtime/`: ignored compiled plugins; `upstream.json` identifies their source commit.
- `install.py`: explicit backed-up activation, with a source/plugin revision check.

Shell QML and native plugins must be updated together. The launcher sets local
QML imports and the version-helper path. The package-managed plugin tree stays
untouched. `build/runtime/bin/qs` is a local Quickshell rebuilt against system Qt;
`build/runtime/python/caelestia` supplies the current CLI needed for native video
selection. Local launchers provide the import paths without changing packages. Native wallpaper playback replaces the disabled mpvpaper bridge by
default. The upstream profile bypasses all shell patches and personal Hyprland
shortcuts while retaining monitor hardware and application preferences.

The installed configuration is a copy, not a symlink. Edit `customs/`, prepare,
review and install to apply changes. Runtime GUI settings are not automatically
written back into the repository. Old laptop restore instructions and historical
test reports in Git history do not describe this new layout.
