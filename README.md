# Caelestia desktop configuration

The shell source in `quickshell/caelestia/` is an unmodified upstream snapshot.
Personal files and optional patches live in `customs/`. Edit those rather than
upstream or generated files. This checkout is based on `laptop-caelestia`, with
the installed desktop monitor layout, keyboard settings and personal files preserved.

Upstream revision and version are recorded in `customs/upstream.json`.
The original `main` and `laptop` branches use a different, custom shell.

## Prepare and review

```sh
python3 scripts/custom-shell prepare
```

This writes `generated/caelestia/` and `generated/files/`. It does not install,
restart the shell, reload Hyprland or change your running desktop.

Edit `customs/features.json` to enable or disable individual shell patches, then
prepare again. Native upstream wallpapers are the default. The old wallpaper
bridge is retained but disabled. The corner-click sidebar is enabled.
See [customs/README.md](customs/README.md) for the feature list.

To prepare the unmodified upstream shell with default Hyprland shortcuts:

```sh
python3 scripts/custom-shell prepare --mode upstream
```

The monitor layout, US keyboard and secondary-monitor bar/lock settings remain.
Kitty, Zsh and other application settings remain personal in both profiles.

## Update from your shell clone

Update your `~/shell` clone using your normal Git workflow, then run:

```sh
python3 scripts/custom-shell update --source ~/shell --ref HEAD
python3 scripts/custom-shell prepare
python3 scripts/custom-shell build
```

The update takes an exact Git commit, checks enabled patches in a temporary
copy, then replaces only the pristine source snapshot. A conflict stops the
update before replacing the old snapshot. Disabled legacy patches do not block
updates; check them before re-enabling them. `prepare` also checks patches before
replacing the last generated profile. Neither command fetches or installs.

The build uses CMake/Ninja and dependencies documented in the upstream
[README](quickshell/caelestia/README.md). It stages matching compiled plugins
under `build/runtime/`, using two jobs by default. Nothing is installed globally.

## Install when ready

The setup uses a local Quickshell binary rebuilt against system Qt, plus an
updated local Caelestia CLI for native video selection. Their source revisions
are recorded in `customs/dependencies.json`. They do not replace system packages.
To rebuild/stage these from local checkouts:

```sh
python3 scripts/custom-shell build-quickshell --source /path/to/quickshell
python3 scripts/custom-shell build-cli --source /path/to/cli
```

Rebuild Quickshell whenever the system Qt version changes. After reviewing the
generated files and staging the matching runtime:

```sh
python3 install.py --mode custom
```

Use `--mode upstream` to install the upstream profile. Run `install.py` again to
switch profiles after editing `customs/features.json`. Installation copies files
and matching local plugins, backs up replaced destinations under
`~/.local/state/caelestia-config-backups/`, refreshes the cheatsheet and reloads
user service definitions. Native-wallpaper mode stops the old wallpaper service.
The script does not restart the shell or reload Hyprland; log out and back in.

The installed launchers `~/.local/bin/caelestia-custom-shell`, `qs` and `caelestia`
use the local runtime and matching plugin imports. The shell launcher is used by
Hyprland at login. Existing IPC calls continue to use `qs -c caelestia`.

The previous video selection remains in the old bridge state. Choose its original
video file in upstream settings to use native playback; old thumbnail images
are not automatically migrated into video selections.

## Checks

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
lua tests/test_shortcuts.lua "$PWD/customs/files/caelestia"
node tests/test_bar_and_scratchpads.js
```

Prepare the custom profile before running the JavaScript checks. The restore
integration test needs the staged runtime from the build step and uses a
temporary home directory with a fake systemctl command.
