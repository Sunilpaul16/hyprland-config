# Personal Caelestia shell features

This folder is the source of the personal shell changes. The recorded upstream
baseline is **5cbf60e7**. Overlapping wallpaper/game-mode/sidebar implementations
are archived and disconnected; see [`../../UPSTREAM-MERGE.md`](../../UPSTREAM-MERGE.md).

| Folder | Purpose |
|---|---|
| `components/` | Independent custom QML and JavaScript implementations |
| `integrations/` | Upstream QML with the hooks and remaining edits required to use those implementations |
| `patches/` | Reviewable upstream changes grouped into eight active feature patches |
| `base/` | Original upstream files used for three-way conflict checks |
| `manifest.json` | Baseline commit, source paths and feature ownership |

The corresponding files in `quickshell/caelestia/` are relative links to their
sources here. `quickshell/caelestia/custom` links to `components/`, imported as
`qs.custom`. There is one editable source for each custom file. The installer
follows those links and installs regular files, so the installed shell does not
depend on the checkout's location. Editing here changes the checkout immediately;
it does not automatically change the installed desktop.

## Active features

The active manifest retains scratchpads/bar labels, manual Wi-Fi scanning,
NightLight, Settings Escape, screenshot saving, shell file-watching preference
the restored sidebar corner click, and the native wallpaper-picker shortcut. Their implementation sources and
integration paths are recorded in `manifest.json`. Generated patches cover only
these active features. The archived implementations have no runtime links.

Native wallpaper playback, previews, game mode and sidebar interactions now use
upstream source. Standalone shortcuts/preferences remain in `../standalone/`.
The installer follows source links and copies regular files into the live config.

## Check a future update

From the repository root:

```sh
python3 scripts/shell-customisations.py check --source ../shell --ref HEAD
```

This uses the upstream clone's existing history, prints results by feature,
follows Git-detected renames, and reports text conflicts or removed upstream
files. It does not fetch, edit or install anything. Exit code 1 means manual
review is needed. A clean text merge still needs API and runtime checks.

When upstream replaces a personal feature, review that feature's patch and
manifest entries together, including its standalone callers. Remove or adapt
the custom implementation and hooks together. Deleting a component alone leaves
unresolved imports. The feature names are an inventory, not runtime switches.

## Generate a shell for review

```sh
python3 scripts/shell-customisations.py build --output /tmp/caelestia-custom-shell
```

This defaults to the recorded baseline. Supply `--ref` to use another upstream
version. The output must be a new directory; conflicts prevent output creation.
The generated directory contains ordinary files, including the custom components.
It is a review artifact, not a replacement for the links in this checkout.
Do not copy it over the repository's source links. Installing or launching a new
shell is a separate step and may require matching compiled Caelestia modules.

After editing components or integration files, refresh the review patches:

```sh
python3 scripts/shell-customisations.py patches
```

These patches are generated for review and export; edit their source files, not
the generated patches. On a baseline-only shell tree, applying all patches
reproduces the linked shell sources. After completing an upstream migration,
refresh the integration files, baseline copies and manifest together, then
regenerate the patches. Do not just change the baseline commit.

## Verification

The standard Python, Lua and JavaScript checks are listed in the main README.
`python3 tests/check_shell_qml.py` also compiles the integrated QML using the
installed Quickshell modules. It needs access to a Wayland session and uses an
isolated temporary configuration. It compiles components without instantiating
the shell's windows or custom services. Successful compilation does not replace
physical desktop interaction checks.
