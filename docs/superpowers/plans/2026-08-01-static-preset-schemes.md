# Static Preset Colour Schemes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 24 static colour schemes (catppuccin, gruvbox, dracula, nord, …) as an alternative to the wallpaper-derived palette, themed across every surface `switchwall` covers, with wallpaper changes leaving them alone.

**Architecture:** A Python helper turns a caelestia preset `.txt` into (a) a matugen JSON palette and (b) an SCSS-shaped stream for kitty. A new `scripts/setscheme` orchestrates: validate → `matugen json` renders the six existing templates → kitty filter → gsettings → state → reload. The colour half of `switchwall` is extracted into a sourced library so both entrypoints share one implementation. The shell reads a `color_source` state file exactly as it already reads `color_mode`.

**Tech Stack:** bash, python3 (stdlib only), matugen 4.1.0, QML/Quickshell (Qt 6).

## Global Constraints

- **No test suite, no CI, no build.** Verification is: lint the QML, run the command, **diff generated output against source values**, exercise live. A zero exit code is never sufficient evidence.
- **Qt 6 qmllint only.** `/usr/bin/qmllint` is Qt 5's and near-useless here. Use the full command in Task 6.
- **Editing this repo edits the live config.** There is no deploy step. `hypr/colors.lua`, `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, `kitty/theme.conf`, `hypr/hyprlock/colors.conf` are gitignored generated output — never commit them.
- **Preset corpus is read from the installed `caelestia` package**, never vendored. Locate it by globbing `/usr/lib/python3.*/site-packages/caelestia/data/schemes` — never hardcode `python3.14`.
- **Parse traps, both mandatory:** read preset files **line-wise** (18 of 29 lack a trailing newline; `split("\n")[:-1]` silently eats the last key), and **lowercase every hex value** (case is inconsistent across and within files).
- **Templates need exactly 34 roles; kitty's template needs exactly 33 names.** Validate both before writing anything. A missing kitty name is emitted literally as `color255 #$primary #`, which kitty refuses to parse.
- **QML comment style:** terse structural signposts only (`// IPC handler`), never explanations. Don't caption a block whose identifier already says what it is.
- **Corner rounding uses `Motion.rounding.*` steps**, never raw literals. A circle is `radius: width / 2`.
- **Settings rows carry `live: true`** when backed by something real; the flag defaults false and renders the label in `Colors.error`.
- **One commit per logical change.** Work on branch `feat/static-preset-schemes`.

## Deviation from the spec

The spec proposed `theming.source` and `theming.preset` config keys **and** a `color_source` state file. This plan uses **only the state file**. `services/Theme.qml` already establishes the pattern — it reads `color_mode` from state via `FileView` rather than mirroring it into `Config`, with a comment explaining that an external `switchwall --mode dark` must stay in sync. Two copies would be a second source of truth. No `Config.qml` change is needed anywhere in this plan, which also means CLAUDE.md's `property alias` trap does not apply.

## File structure

| File | Responsibility |
| --- | --- |
| `scripts/lib/preset-palette.py` (new) | Pure data. Locate corpus, list schemes, parse a preset, validate, emit matugen JSON or SCSS. No side effects. |
| `scripts/lib/apply-colors.sh` (new) | Shared apply steps: `cfg`/`cfgbool`, kitty filter, gsettings, reloads. |
| `scripts/setscheme` (new) | Orchestration + CLI. Sources the library, calls the helper. |
| `scripts/switchwall` (modify) | Sources the library; honours `color_source`; ordering fix. |
| `quickshell/shell/services/Schemes.qml` (new) | Lists the corpus for the UI; reads one preset for swatches/preview. |
| `quickshell/shell/services/Theme.qml` (modify) | Gains `source`/`preset` state and `applyPreset()`/`setDynamic()`. |
| `quickshell/shell/services/ColorsLoader.qml` (modify) | Gains `previewPalette()` — preview with no subprocess. |
| `quickshell/shell/modules/settings/SchemesSubPage.qml` (new) | The picker. |
| `quickshell/shell/modules/settings/WallpaperStylePage.qml` (modify) | Colour-source row + Presets pill. |
| `quickshell/shell/modules/settings/Content.qml` (modify) | Registers the sub-page. |

---

### Task 1: Extract the shared apply library

Behaviour-preserving refactor. `switchwall` must produce byte-identical output afterwards.

**Files:**
- Create: `scripts/lib/apply-colors.sh`
- Modify: `scripts/switchwall`

**Interfaces:**
- Produces: `cfg <jq-path> <default>`, `cfgbool <jq-path> <default>`, `apply_kitty_from_scss <scss-path>`, `apply_gsettings <light|dark>`, `reload_all`. All read `$CONFIG_FILE`, `$COLORGEN_DIR`, `$KITTY_THEME_OUT` from the caller's environment.

- [ ] **Step 1: Capture a baseline of the current output**

```bash
cd ~/hyprland-config
mkdir -p /tmp/baseline
switchwall --noswitch
md5sum ~/.config/hypr/colors.lua ~/.config/hypr/hyprlock/colors.conf \
        ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css \
        ~/.config/btop/themes/matugen.theme \
        ~/.local/state/quickshell/colors.json \
        ~/.config/kitty/theme.conf > /tmp/baseline/before.md5
cat /tmp/baseline/before.md5
```

Expected: seven checksums printed.

- [ ] **Step 2: Create the library**

```bash
mkdir -p scripts/lib
```

Create `scripts/lib/apply-colors.sh`:

```bash
#!/usr/bin/env bash

# Shared colour-apply steps. Sourced by switchwall and setscheme so both
# reach every themed app by one implementation. Expects the caller to have
# set CONFIG_FILE, COLORGEN_DIR and KITTY_THEME_OUT.

# cfg <jq-path> <default> — missing file, missing key or null all fall back
cfg() {
    local value=""
    if [[ -s "$CONFIG_FILE" ]]; then
        value="$(jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null || true)"
    fi
    [[ -n "$value" ]] && printf '%s' "$value" || printf '%s' "$2"
}

# cfgbool <jq-path> <default> — booleans cannot go through cfg: jq's `//`
# treats a literal `false` as absent, so `false` would read back as the
# default. Only null/missing falls back here.
cfgbool() {
    local value=""
    if [[ -s "$CONFIG_FILE" ]]; then
        value="$(jq -r "$1 | if . == null then empty else . end" "$CONFIG_FILE" 2>/dev/null || true)"
    fi
    [[ -n "$value" ]] && printf '%s' "$value" || printf '%s' "$2"
}

# apply_kitty_from_scss <scss-path> — rewrites the kitty theme from a stream
# of `$name: #RRGGBB;` lines. Generator-agnostic: matugen's materialyoucolor
# pass and a static preset both feed it the same shape.
apply_kitty_from_scss() {
    local scss="$1"
    cp "$COLORGEN_DIR/terminal/kitty-theme.conf" "$KITTY_THEME_OUT"
    local name value hexval
    while IFS=: read -r name value; do
        [[ -z "$name" ]] && continue
        hexval="$(echo "$value" | tr -d ' ;')"
        hexval="${hexval#\#}"
        sed -i "s/${name} #/${hexval}/g" "$KITTY_THEME_OUT"
    done < "$scss"

    # Terminal window transparency. dynamic_background_opacity is what lets
    # kitty pick this up on SIGUSR1 instead of needing a restart
    local opacity
    opacity="$(cfg '.theming.terminalOpacity' '1.0')"
    {
        echo ""
        echo "# Written by switchwall from theming.terminalOpacity"
        echo "dynamic_background_opacity yes"
        echo "background_opacity $opacity"
    } >> "$KITTY_THEME_OUT"
}

# apply_gsettings <light|dark> — GTK4 renders the wrong @media block without this
apply_gsettings() {
    if [[ "$1" == light ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    fi
    nautilus -q || true
}

reload_all() {
    hyprctl reload >/dev/null
    pkill -SIGUSR1 -x kitty >/dev/null 2>&1 || true
}
```

- [ ] **Step 3: Move monitor derivation behind the wallpaper branch**

In `scripts/switchwall`, delete lines 8-9 (the `mapfile` and the guard) from the top block. Insert them inside the wallpaper-display `if` at what is currently line 129, immediately after the `if` line:

```bash
    mapfile -t MONITORS < <(grep -oP 'hl\.monitor\(\{\s*output\s*=\s*"\K[^"]+' "$HYPR_GENERAL")
    [[ ${#MONITORS[@]} -gt 0 ]] || { echo "switchwall: no monitors found in $HYPR_GENERAL" >&2; exit 1; }
```

Then move the `mpvpaper` preflight (line 116) from the unconditional block into that same `if`, directly below:

```bash
    command -v mpvpaper >/dev/null || { echo "switchwall: mpvpaper not found" >&2; exit 1; }
```

This fixes the pre-existing bug where `--colors-preview` and `--noswitch` die on an unreadable `general.lua` despite setting no wallpaper.

- [ ] **Step 4: Source the library and delete the duplicated bodies**

In `scripts/switchwall`, immediately after the `KITTY_THEME_OUT` assignment (line 13), add:

```bash
# shellcheck source=lib/apply-colors.sh
source "$(dirname "$(readlink -f "$0")")/lib/apply-colors.sh"
```

Then delete the now-duplicated definitions of `cfg` (lines 26-33) and `cfgbool` (lines 35-44). Replace lines 236-252 (the `cp`/`while`/opacity block) with:

```bash
apply_kitty_from_scss "$scss"
```

Replace lines 204-211 (the gsettings `if` and `nautilus -q`) with:

```bash
apply_gsettings "$MODE"
```

Replace lines 255-256 (`hyprctl reload` and `pkill`) with:

```bash
reload_all
```

- [ ] **Step 5: Verify byte-identical output**

```bash
switchwall --noswitch
md5sum ~/.config/hypr/colors.lua ~/.config/hypr/hyprlock/colors.conf \
        ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css \
        ~/.config/btop/themes/matugen.theme \
        ~/.local/state/quickshell/colors.json \
        ~/.config/kitty/theme.conf > /tmp/baseline/after.md5
diff /tmp/baseline/before.md5 /tmp/baseline/after.md5 && echo "IDENTICAL"
```

Expected: `IDENTICAL`. Any difference means the refactor changed behaviour — fix before continuing.

- [ ] **Step 6: Verify the ordering fix**

```bash
WALL="$(cat ~/.local/state/quickshell/current_wallpaper)"
mv ~/.config/hypr/general.lua /tmp/general.lua.bak
switchwall --colors-preview "$WALL"; rc=$?
mv /tmp/general.lua.bak ~/.config/hypr/general.lua
echo "exit was $rc"
```

Expected: prints `switchwall: colours preview written (...)` and `exit was 0`. Before this task it exited 1. The `mv` back runs regardless — **if you interrupt this step, restore `general.lua` by hand before doing anything else.**

- [ ] **Step 7: Commit**

```bash
git add scripts/lib/apply-colors.sh scripts/switchwall
git commit -m "scripts: extract the shared colour-apply library

Moves cfg/cfgbool, the kitty filter, gsettings and the reloads into a
sourced library so a second entrypoint cannot drift from switchwall.

Also moves monitor derivation and the mpvpaper preflight behind the
wallpaper branch — both ran before argument parsing, so --colors-preview
and --noswitch died on an unreadable general.lua despite setting no
wallpaper."
```

---

### Task 2: Preset parsing and validation helper

Pure data, no side effects. Everything that can go wrong with the corpus is caught here.

**Files:**
- Create: `scripts/lib/preset-palette.py`

**Interfaces:**
- Produces CLI: `preset-palette.py list` → one `scheme/flavour<TAB>modes` line per flavour. `preset-palette.py matugen <scheme>/<flavour> <light|dark>` → matugen JSON on stdout. `preset-palette.py scss <scheme>/<flavour> <light|dark>` → `$name: #hex;` lines on stdout. `preset-palette.py modes <scheme>/<flavour>` → space-separated available modes. All exit 2 on a bad preset id, 3 if the corpus is missing.

- [ ] **Step 1: Write the helper**

Create `scripts/lib/preset-palette.py`:

```python
#!/usr/bin/env python3
"""Turns a caelestia preset .txt into what this repo's pipeline consumes.

Read-only against the installed caelestia package; emits matugen JSON or the
SCSS-shaped stream the kitty filter eats. No side effects, no writes.
"""

import glob
import json
import os
import sys

# Roles the six matugen templates reference. A missing one renders a literal
# {{colors.x.default.hex}} into a live config, so this is validated up front.
TEMPLATE_ROLES = [
    "background", "error", "errorContainer", "inverseOnSurface", "inversePrimary",
    "inverseSurface", "onBackground", "onError", "onErrorContainer", "onPrimary",
    "onPrimaryContainer", "onPrimaryFixed", "onSecondaryContainer", "onSurface",
    "onSurfaceVariant", "outline", "outlineVariant", "primary", "primaryContainer",
    "primaryFixed", "primaryFixedDim", "secondary", "secondaryContainer",
    "secondaryFixedDim", "surface", "surfaceContainer", "surfaceContainerHigh",
    "surfaceContainerHighest", "surfaceContainerLow", "surfaceContainerLowest",
    "surfaceVariant", "tertiary", "tertiaryContainer", "tertiaryFixedDim",
]

# Names kitty-theme.conf substitutes. Unsupplied ones survive as literal
# `$primary` text that kitty refuses to parse, so all 33 are required.
KITTY_NAMES = [f"term{i}" for i in range(16)] + [
    "primary", "primaryContainer", "secondary", "secondaryContainer",
    "onSecondaryContainer", "tertiary", "tertiaryContainer", "error",
    "errorContainer", "onPrimary", "onPrimaryContainer", "onSecondary",
    "onTertiary", "onTertiaryContainer", "onError", "onErrorContainer",
    "outlineVariant",
]


def camel_to_snake(name):
    out = []
    for ch in name:
        if ch.isupper():
            out.append("_")
            out.append(ch.lower())
        else:
            out.append(ch)
    return "".join(out)


def corpus_dir():
    # Globbed, never hardcoded — the path carries a Python version
    matches = sorted(glob.glob("/usr/lib/python3.*/site-packages/caelestia/data/schemes"))
    if not matches:
        sys.exit("preset-palette: caelestia package not found; presets unavailable")
    return matches[-1]


def list_flavours():
    root = corpus_dir()
    rows = []
    for scheme in sorted(os.listdir(root)):
        sdir = os.path.join(root, scheme)
        if not os.path.isdir(sdir):
            continue
        for flavour in sorted(os.listdir(sdir)):
            fdir = os.path.join(sdir, flavour)
            if not os.path.isdir(fdir):
                continue
            modes = sorted(
                os.path.splitext(f)[0] for f in os.listdir(fdir) if f.endswith(".txt")
            )
            if modes:
                rows.append((f"{scheme}/{flavour}", modes))
    return rows


def resolve_mode(preset, want):
    for pid, modes in list_flavours():
        if pid == preset:
            # Silent fallback: 17 of 24 flavours are dark-only
            return want if want in modes else modes[0]
    sys.exit(2)


def read_preset(preset, mode):
    path = os.path.join(corpus_dir(), preset, f"{mode}.txt")
    if not os.path.isfile(path):
        sys.exit(2)
    colours = {}
    # Line-wise: 18 of 29 files have no trailing newline, so a split("\n")
    # based read drops the last key from those
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            key, _, value = line.partition(" ")
            # Case is inconsistent across and within files
            colours[key] = value.strip().lower()
    return colours


def require(colours, names, what):
    missing = [n for n in names if n not in colours]
    if missing:
        sys.exit(f"preset-palette: preset missing {what}: {', '.join(missing)}")


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: preset-palette.py list|modes|matugen|scss ...")
    cmd = sys.argv[1]

    if cmd == "list":
        for pid, modes in list_flavours():
            print(f"{pid}\t{' '.join(modes)}")
        return

    if cmd == "modes":
        for pid, modes in list_flavours():
            if pid == sys.argv[2]:
                print(" ".join(modes))
                return
        sys.exit(2)

    preset, want = sys.argv[2], sys.argv[3]
    mode = resolve_mode(preset, want)
    colours = read_preset(preset, mode)

    if cmd == "matugen":
        require(colours, TEMPLATE_ROLES, "template roles")
        out = {}
        for role in TEMPLATE_ROLES:
            value = "#" + colours[role]
            # One palette drives all three variants; a preset has one mode
            out[camel_to_snake(role)] = {
                "default": {"color": value},
                "light": {"color": value},
                "dark": {"color": value},
            }
        json.dump({"colors": out}, sys.stdout)
        return

    if cmd == "scss":
        require(colours, KITTY_NAMES, "kitty names")
        for name in KITTY_NAMES:
            print(f"${name}: #{colours[name]};")
        return

    sys.exit(f"preset-palette: unknown command {cmd}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Verify the corpus listing**

```bash
chmod +x scripts/lib/preset-palette.py
scripts/lib/preset-palette.py list | wc -l
scripts/lib/preset-palette.py list | grep -E 'gruvbox|dracula|catppuccin'
```

Expected: `24`. The grep shows `gruvbox/hard	dark light`, `dracula/medium	dark`, `catppuccin/latte	light`.

- [ ] **Step 3: Verify every preset parses and validates**

```bash
fail=0
while IFS=$'\t' read -r pid modes; do
  for m in $modes; do
    scripts/lib/preset-palette.py matugen "$pid" "$m" >/dev/null || { echo "MATUGEN FAIL $pid $m"; fail=1; }
    scripts/lib/preset-palette.py scss "$pid" "$m" >/dev/null || { echo "SCSS FAIL $pid $m"; fail=1; }
  done
done < <(scripts/lib/preset-palette.py list)
[ $fail -eq 0 ] && echo "ALL 29 FILES OK"
```

Expected: `ALL 29 FILES OK`. This proves all 34 roles and all 33 kitty names exist everywhere.

- [ ] **Step 4: Verify the parse traps are handled**

```bash
# gruvbox/medium/dark.txt has no trailing newline — the last key must survive
scripts/lib/preset-palette.py scss gruvbox/medium dark | tail -3
# dracula is largely uppercase — every emitted value must be lowercase
scripts/lib/preset-palette.py scss dracula/medium dark | grep -c '[A-F]'
```

Expected: the `tail` shows three `$name: #hex;` lines with real values. The `grep -c` prints `0`.

- [ ] **Step 5: Verify the silent mode fallback**

```bash
scripts/lib/preset-palette.py matugen dracula/medium light | head -c 60; echo
scripts/lib/preset-palette.py modes catppuccin/latte
```

Expected: the first emits valid JSON (falling back to dark, not erroring). The second prints `light`.

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/preset-palette.py
git commit -m "scripts: add the preset palette helper

Parses a caelestia preset into matugen JSON or the SCSS stream the kitty
filter consumes, validating all 34 template roles and all 33 kitty names
before emitting anything.

Reads line-wise and lowercases values — 18 of the 29 files have no
trailing newline and hex case is inconsistent across and within them."
```

---

### Task 3: `setscheme` applies a preset

**Files:**
- Create: `scripts/setscheme`

**Interfaces:**
- Consumes: `apply_kitty_from_scss`, `apply_gsettings`, `reload_all`, `cfg` from Task 1; `preset-palette.py` from Task 2.
- Produces: `setscheme <scheme>/<flavour>` applies a preset. `setscheme --list` lists them. Writes `~/.local/state/quickshell/color_source`.

- [ ] **Step 1: Write the script**

Create `scripts/setscheme`:

```bash
#!/usr/bin/env bash

set -euo pipefail

# Paths and constants
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
COLORGEN_DIR="$HOME/.config/matugen/colorgen"
CACHE_DIR="$HOME/.cache/matugen"
KITTY_THEME_OUT="$HOME/.config/kitty/theme.conf"
CONFIG_FILE="$HOME/.config/quickshell/config.json"
MODE_FILE="$HOME/.local/state/quickshell/color_mode"
SOURCE_FILE="$HOME/.local/state/quickshell/color_source"
HELPER="$SCRIPT_DIR/lib/preset-palette.py"

# shellcheck source=lib/apply-colors.sh
source "$SCRIPT_DIR/lib/apply-colors.sh"

usage() {
    echo "Usage: $(basename "$0") <scheme>/<flavour>   (e.g. gruvbox/medium)" >&2
    echo "       $(basename "$0") dynamic              (back to wallpaper colours)" >&2
    echo "       $(basename "$0") --list" >&2
    exit 1
}

[[ $# -eq 1 ]] || usage

case "$1" in
    --list) exec "$HELPER" list ;;
    -*)     usage ;;
esac

TARGET="$1"

for bin in matugen jq gsettings hyprctl; do
    command -v "$bin" >/dev/null || { echo "setscheme: $bin not found" >&2; exit 1; }
done

mkdir -p "$CACHE_DIR" "$(dirname "$SOURCE_FILE")"

# Back to wallpaper-derived colours — switchwall owns that path, so delegate
if [[ "$TARGET" == dynamic ]]; then
    printf '%s' dynamic > "$SOURCE_FILE"
    exec switchwall --noswitch
fi

# Resolve the mode. A preset carries its own; 17 of 24 flavours are dark-only,
# so the requested mode is a preference, not a guarantee
WANT_MODE=dark
[[ -s "$MODE_FILE" ]] && WANT_MODE="$(cat "$MODE_FILE")"
[[ "$WANT_MODE" == auto ]] && WANT_MODE=dark

AVAILABLE="$("$HELPER" modes "$TARGET")" || { echo "setscheme: unknown preset '$TARGET'" >&2; exit 1; }
MODE="$WANT_MODE"
[[ " $AVAILABLE " == *" $WANT_MODE "* ]] || {
    MODE="${AVAILABLE%% *}"
    echo "setscheme: $TARGET has no $WANT_MODE mode, using $MODE"
}

# Validate and generate before touching anything, so a rejected preset
# leaves the existing theme intact
palette="$CACHE_DIR/preset_palette.json"
scss="$CACHE_DIR/preset_colors.scss"
"$HELPER" matugen "$TARGET" "$MODE" > "$palette"
"$HELPER" scss "$TARGET" "$MODE" > "$scss"

# Renders the same six templates the wallpaper path uses — matugen's json
# subcommand takes literal values rather than deriving from a seed
matugen json "$palette"

apply_kitty_from_scss "$scss"
apply_gsettings "$MODE"

printf '%s' "$MODE" > "$MODE_FILE"
printf '%s' "$TARGET" > "$SOURCE_FILE"

reload_all

echo "setscheme: done ($TARGET $MODE)"
```

- [ ] **Step 2: Make it executable and symlink it**

```bash
chmod +x scripts/setscheme
ln -sf ~/hyprland-config/scripts/setscheme ~/.local/bin/setscheme
ls -la ~/.local/bin/setscheme
```

Expected: symlink pointing into the repo, matching the other three scripts.

- [ ] **Step 3: Apply a preset and verify against source values**

```bash
setscheme gruvbox/medium
DIR=$(ls -d /usr/lib/python3.*/site-packages/caelestia/data/schemes | tail -1)
SRC="$DIR/gruvbox/medium/dark.txt"
prim=$(grep -oP '^primary \K.*' "$SRC" | tr 'A-F' 'a-f')
echo "source primary: $prim"
grep -o "$prim" ~/.local/state/quickshell/colors.json && echo "colors.json OK"
grep -oi "$prim" ~/.config/gtk-3.0/gtk.css >/dev/null && echo "gtk3 OK"
grep -oi "$prim" ~/.config/btop/themes/matugen.theme >/dev/null && echo "btop OK"
outv=$(grep -oP '^outlineVariant \K.*' "$SRC" | tr 'A-F' 'a-f')
grep -o "$outv" ~/.config/hypr/colors.lua && echo "hyprland OK"
```

Expected: the source primary printed, then `colors.json OK`, `gtk3 OK`, `btop OK`, `hyprland OK`. **This matching hex is the proof — not the script's exit code.**

- [ ] **Step 4: Verify kitty has no unsubstituted placeholders**

```bash
grep -n '\$' ~/.config/kitty/theme.conf || echo "NO PLACEHOLDERS LEFT"
t0=$(grep -oP '^term0 \K.*' "$SRC" | tr 'A-F' 'a-f')
grep -q "$t0" ~/.config/kitty/theme.conf && echo "kitty term0 OK"
```

Expected: `NO PLACEHOLDERS LEFT` then `kitty term0 OK`. Any surviving `$name` means a missing role.

- [ ] **Step 5: Verify state and the dark-only fallback**

```bash
cat ~/.local/state/quickshell/color_source; echo
cat ~/.local/state/quickshell/color_mode; echo
echo light > ~/.local/state/quickshell/color_mode
setscheme dracula/medium
```

Expected: `gruvbox/medium` then `dark`. The last command prints `setscheme: dracula/medium has no light mode, using dark` and succeeds.

- [ ] **Step 6: Verify a bad preset changes nothing**

```bash
md5sum ~/.local/state/quickshell/colors.json > /tmp/before.md5
setscheme nosuch/thing || echo "rejected as expected"
md5sum -c /tmp/before.md5 && echo "THEME UNTOUCHED"
```

Expected: `rejected as expected` then `THEME UNTOUCHED`.

- [ ] **Step 7: Commit**

```bash
git add scripts/setscheme
git commit -m "scripts: add setscheme for static preset palettes

Renders the same six templates the wallpaper path uses, via matugen's
json subcommand, so preset and dynamic output cannot drift. Validates
before writing, so a rejected preset leaves the existing theme intact."
```

---

### Task 4: `switchwall` honours the active preset

**Files:**
- Modify: `scripts/switchwall`

**Interfaces:**
- Consumes: `~/.local/state/quickshell/color_source` written by Task 3.

- [ ] **Step 1: Add the state path**

In `scripts/switchwall`, after the `MODE_FILE` assignment (line 16), add:

```bash
# setscheme owns this; a preset means colours are deliberately not
# wallpaper-derived, so a wallpaper change must leave them alone
SOURCE_FILE="$HOME/.local/state/quickshell/color_source"
```

- [ ] **Step 2: Branch before colour generation**

In `scripts/switchwall`, immediately before the `# --- 3. matugen:` comment, insert:

```bash
COLOR_SOURCE=dynamic
[[ -s "$SOURCE_FILE" ]] && COLOR_SOURCE="$(cat "$SOURCE_FILE")"
if [[ "$COLOR_SOURCE" != dynamic ]] && ! $COLORS_PREVIEW; then
    echo "switchwall: wallpaper set; colours held by preset $COLOR_SOURCE"
    exit 0
fi
```

- [ ] **Step 3: Verify colours survive a wallpaper change**

```bash
setscheme gruvbox/medium
md5sum ~/.local/state/quickshell/colors.json ~/.config/kitty/theme.conf > /tmp/preset.md5
WALL=$(find ~/wallpaper -type f \( -name '*.jpg' -o -name '*.png' \) | head -1)
echo "using $WALL"
switchwall "$WALL"
md5sum -c /tmp/preset.md5 && echo "COLOURS HELD"
cat ~/.local/state/quickshell/current_wallpaper; echo
```

Expected: `switchwall: wallpaper set; colours held by preset gruvbox/medium`, then `COLOURS HELD`, then the new wallpaper path — proving the wallpaper *did* change while colours did not.

- [ ] **Step 4: Verify returning to dynamic regenerates**

```bash
setscheme dynamic
md5sum -c /tmp/preset.md5 2>&1 | grep -q FAILED && echo "COLOURS REGENERATED"
cat ~/.local/state/quickshell/color_source; echo
```

Expected: `COLOURS REGENERATED` then `dynamic`.

- [ ] **Step 5: Commit**

```bash
git add scripts/switchwall
git commit -m "scripts: hold colours while a preset is active

A wallpaper change now sets the wallpaper and stops before colour
generation unless the source is dynamic, so picking a preset is a
deliberate opt-out of wallpaper theming rather than a temporary look."
```

---

### Task 5: `Schemes.qml` and `Theme.qml` state

**Files:**
- Create: `quickshell/shell/services/Schemes.qml`
- Modify: `quickshell/shell/services/Theme.qml`

**Interfaces:**
- Produces: `Schemes.list` — array of `{ id, scheme, flavour, modes }`. `Schemes.loadPreset(id, mode)` → fills `Schemes.colours` (a `roleName -> "#hex"` map) and emits `presetLoaded(id)`. `Theme.source` (string, `"dynamic"` or a preset id), `Theme.applyPreset(id)`, `Theme.setDynamic()`.

- [ ] **Step 1: Create the service**

Create `quickshell/shell/services/Schemes.qml`:

```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Static preset palettes, read from the installed caelestia package via
// scripts/lib/preset-palette.py. Listing is one shot; an individual preset
// is read on demand for swatches and preview
Singleton {
    id: root

    // [{ id, scheme, flavour, modes }]
    property var list: []
    property bool available: true
    // roleName -> "#rrggbb" for the most recently loaded preset
    property var colours: ({})

    signal presetLoaded(string id)

    function loadPreset(id: string, mode: string): void {
        root._pendingId = id;
        readProc.command = [Directories.presetHelper, "matugen", id, mode];
        readProc.running = true;
    }

    property string _pendingId: ""

    Process {
        id: listProc

        running: true
        command: [Directories.presetHelper, "list"]

        onExited: exitCode => {
            if (exitCode !== 0)
                root.available = false;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const [id, modes] = line.split("\t");
                    const [scheme, flavour] = id.split("/");
                    rows.push({
                        id: id,
                        scheme: scheme,
                        flavour: flavour,
                        modes: modes ? modes.split(" ") : []
                    });
                }
                root.list = rows;
                root.available = rows.length > 0;
            }
        }
    }

    Process {
        id: readProc

        stdout: StdioCollector {
            onStreamFinished: {
                let json;
                try {
                    json = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const flat = {};
                for (const role in json.colors)
                    flat[role] = json.colors[role].default.color;
                root.colours = flat;
                root.presetLoaded(root._pendingId);
            }
        }
    }
}
```

- [ ] **Step 2: Add the helper paths**

In `quickshell/shell/services/Directories.qml`, after the `switchwallScript` line, add:

```qml
    readonly property string setschemeScript: localBin + "/setscheme"
    readonly property string presetHelper: repoRoot + "/scripts/lib/preset-palette.py"
    readonly property string colorSourceFile: home + "/.local/state/quickshell/color_source"
```

- [ ] **Step 3: Add source state to `Theme.qml`**

In `quickshell/shell/services/Theme.qml`, after the `busy` property, add:

```qml
    // "dynamic" | "<scheme>/<flavour>" — setscheme owns the backing file, so
    // read it rather than mirroring it into Config
    property string source: "dynamic"
    readonly property bool usingPreset: root.source !== "dynamic"
```

After the `regenerate()` function, add:

```qml
    function applyPreset(id: string): void {
        if (root.busy)
            return;
        root.busy = true;
        modeProc.command = [Directories.setschemeScript, id];
        modeProc.running = true;
    }

    function setDynamic(): void {
        if (root.busy || !root.usingPreset)
            return;
        root.busy = true;
        modeProc.command = [Directories.setschemeScript, "dynamic"];
        modeProc.running = true;
    }
```

At the end of the `Singleton` body, add:

```qml
    FileView {
        path: Directories.colorSourceFile
        watchChanges: true

        onLoaded: {
            const value = text().trim();
            if (value.length > 0)
                root.source = value;
        }
        onFileChanged: reload()
    }
```

- [ ] **Step 4: Lint**

```bash
cd ~/hyprland-config
/usr/lib/qt6/bin/qmllint -I quickshell/shell -I /usr/lib/qt6/qml \
  --missing-property disable --import disable --unqualified disable \
  --unresolved-type disable --missing-type disable --incompatible-type disable \
  --uncreatable-type disable \
  quickshell/shell/services/Schemes.qml quickshell/shell/services/Theme.qml \
  quickshell/shell/services/Directories.qml
```

Expected: exit 0. Ignore any `QProcess::ExitStatus ... was not found` on `onExited` — that is the one known false positive.

- [ ] **Step 5: Verify the service loads and lists**

```bash
pkill -x qs; (qs -n -c shell > /tmp/qs.log 2>&1 &) ; sleep 4
grep -c "Configuration Loaded" /tmp/qs.log
grep -i "error" /tmp/qs.log | head
```

Expected: at least `1`, and no errors. A clean `Configuration Loaded` is the real evidence the signal wiring is valid — lint cannot prove it.

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell/services/Schemes.qml quickshell/shell/services/Theme.qml \
        quickshell/shell/services/Directories.qml
git commit -m "shell: add the preset scheme service

Schemes lists the corpus and reads one preset on demand; Theme gains the
active source, read from setscheme's state file rather than mirrored into
Config so an external setscheme run stays in sync."
```

---

### Task 6: Preview without a subprocess

**Files:**
- Modify: `quickshell/shell/services/ColorsLoader.qml`

**Interfaces:**
- Consumes: `Schemes.colours` from Task 5.
- Produces: `ColorsLoader.previewPalette(map)` — applies a `roleName -> "#hex"` map as a preview. `clearPreview()` reverts it, unchanged.

- [ ] **Step 1: Add the function**

In `quickshell/shell/services/ColorsLoader.qml`, after `clearPreview()`, add:

```qml
    // A preset's colours are already on disk, so unlike preview() there is
    // nothing to generate — no Process, no wait. Maps the template role names
    // onto the shell's own, then reuses the same revert path
    function previewPalette(palette: var): void {
        if (!palette || !palette.primary)
            return;
        root.previewPath = "";
        root.pendingPath = "";
        root.previewing = true;
        root.applyColors(JSON.stringify({
            background: palette.background,
            surface: palette.surface_container,
            primary: palette.primary,
            secondary: palette.secondary,
            tertiary: palette.tertiary,
            secondaryContainer: palette.secondary_container,
            text: palette.on_surface,
            textMuted: palette.on_surface_variant,
            outline: palette.outline,
            outlineVariant: palette.outline_variant,
            error: palette.error,
            textOnError: palette.on_error,
            errorContainer: palette.error_container,
            textOnErrorContainer: palette.on_error_container
        }));
    }
```

The key mapping mirrors `matugen/templates/colors-json/colors.json` exactly — the same 14 roles the real palette uses.

- [ ] **Step 2: Lint**

```bash
cd ~/hyprland-config
/usr/lib/qt6/bin/qmllint -I quickshell/shell -I /usr/lib/qt6/qml \
  --missing-property disable --import disable --unqualified disable \
  --unresolved-type disable --missing-type disable --incompatible-type disable \
  --uncreatable-type disable \
  quickshell/shell/services/ColorsLoader.qml
```

Expected: exit 0.

- [ ] **Step 3: Verify preview and revert live**

```bash
pkill -x qs; (qs -n -c shell > /tmp/qs.log 2>&1 &) ; sleep 4
grep -c "Configuration Loaded" /tmp/qs.log
```

Then confirm the revert path is intact by exercising the existing wallpaper preview, which shares it:

```bash
qs -c shell ipc call settings open
qs -c shell ipc call settings sub wallpapers
```

Hover a wallpaper tile, confirm the shell repaints, then Escape and confirm it returns. Expected: repaint on hover, exact revert on Escape.

- [ ] **Step 4: Commit**

```bash
git add quickshell/shell/services/ColorsLoader.qml
git commit -m "shell: preview a preset palette without generating one

A preset's colours already exist, so previewing one needs no matugen run
and no Process — it maps straight onto the shell's roles and reuses the
existing revert."
```

---

### Task 7: The picker

**Files:**
- Create: `quickshell/shell/modules/settings/SchemesSubPage.qml`
- Modify: `quickshell/shell/modules/settings/Content.qml`
- Modify: `quickshell/shell/modules/settings/WallpaperStylePage.qml`

**Interfaces:**
- Consumes: `Schemes.list`, `Schemes.loadPreset`, `Schemes.presetLoaded`, `Theme.source`, `Theme.applyPreset`, `Theme.setDynamic`, `ColorsLoader.previewPalette`.

- [ ] **Step 1: Create the sub-page**

Create `quickshell/shell/modules/settings/SchemesSubPage.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Static preset picker, reached from Wallpaper & style's Presets pill.
// Highlighting a row themes the shell with that preset without applying it
ScrollPage {
    id: root

    title: "Colour presets"
    isSubPage: true

    property string hoveredId: ""

    onHoveredIdChanged: {
        if (root.hoveredId)
            Schemes.loadPreset(root.hoveredId, Theme.mode === "light" ? "light" : "dark");
        else
            ColorsLoader.clearPreview();
    }

    Component.onDestruction: ColorsLoader.clearPreview()

    Connections {
        target: Schemes

        function onPresetLoaded(id: string): void {
            if (id === root.hoveredId)
                ColorsLoader.previewPalette(Schemes.colours);
        }
    }

    SectionLabel {
        text: "Presets"
    }

    // Empty state — the corpus lives in the caelestia package, which may not
    // be installed
    Text {
        visible: !Schemes.available
        text: "No presets found. They are read from the caelestia package."
        color: Colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: Schemes.list

            Rectangle {
                id: row

                required property var modelData

                readonly property bool active: row.modelData.id === Theme.source

                Layout.fillWidth: true
                implicitHeight: 52
                radius: Motion.rounding.item
                color: rowArea.containsMouse ? Colors.layer : "transparent"

                MouseArea {
                    id: rowArea

                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: root.hoveredId = row.modelData.id
                    onExited: {
                        if (root.hoveredId === row.modelData.id)
                            root.hoveredId = "";
                    }
                    onClicked: {
                        root.hoveredId = "";
                        ColorsLoader.clearPreview();
                        Theme.applyPreset(row.modelData.id);
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: width / 2
                        color: Colors.surface
                        border.width: 1
                        border.color: Colors.outlineVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: row.modelData.flavour
                            color: Colors.text
                            font.pixelSize: 13
                        }

                        Text {
                            text: row.modelData.scheme
                            color: Colors.textMuted
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        visible: row.active
                        text: "✓"
                        color: Colors.primary
                        font.pixelSize: 15
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Register the sub-page**

In `quickshell/shell/modules/settings/Content.qml`, change the `subPageModel` to:

```qml
    readonly property var subPageModel: ({
        "wallpapers": wallpapersSubPage,
        "schemes": schemesSubPage
    })
```

Then add a `Component` beside the existing `wallpapersSubPage` one:

```qml
    Component {
        id: schemesSubPage

        SchemesSubPage {}
    }
```

- [ ] **Step 3: Add the source row**

In `quickshell/shell/modules/settings/WallpaperStylePage.qml`, immediately **before** the existing `SettingRow` whose label is `"Scheme"`, insert:

```qml
        SettingRow {
            live: true
            label: "Colour source"
            subtext: "Presets ignore the wallpaper"

            SelectMenu {
                options: [
                    { value: "dynamic", label: "Wallpaper" },
                    { value: "preset", label: "Preset" }
                ]
                current: Theme.usingPreset ? "preset" : "dynamic"
                onSelected: v => {
                    if (v === "dynamic")
                        Theme.setDynamic();
                    else
                        SettingsState.subPage = "schemes";
                }
            }
        }
```

Then in the existing `"Scheme"` row, add these two lines directly below `live: true`, so it reads as inert while a preset is active:

```qml
            enabled: !Theme.usingPreset
            opacity: enabled ? 1 : 0.5
```

Finally add a row directly after the `"Scheme"` row:

```qml
        SettingRow {
            live: true
            label: "Presets"
            subtext: Theme.usingPreset ? Theme.source : "Catppuccin, Gruvbox, Dracula and more"

            SelectPill {
                value: "Browse"
                icon: "palette"
                onClicked: SettingsState.subPage = "schemes"
            }
        }
```

- [ ] **Step 4: Lint**

```bash
cd ~/hyprland-config
/usr/lib/qt6/bin/qmllint -I quickshell/shell -I /usr/lib/qt6/qml \
  --missing-property disable --import disable --unqualified disable \
  --unresolved-type disable --missing-type disable --incompatible-type disable \
  --uncreatable-type disable \
  quickshell/shell/modules/settings/SchemesSubPage.qml \
  quickshell/shell/modules/settings/Content.qml \
  quickshell/shell/modules/settings/WallpaperStylePage.qml
```

Expected: exit 0.

- [ ] **Step 5: Verify it loads and opens**

```bash
pkill -x qs; (qs -n -c shell > /tmp/qs.log 2>&1 &) ; sleep 4
grep -c "Configuration Loaded" /tmp/qs.log
grep -iE "error|non-existent" /tmp/qs.log | head
qs -c shell ipc call settings open
qs -c shell ipc call settings sub schemes
```

Expected: at least one `Configuration Loaded`, no errors, and the sub-page opens showing 24 rows.

- [ ] **Step 6: Verify preview, commit and revert live**

Take a screenshot to confirm the list renders:

```bash
hyprctl monitors -j | jq '.[] | {name, focused}'
grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" /tmp/schemes.png
```

Then, by hand: hover a row and confirm the shell repaints; move away and confirm it reverts; click a row and confirm the theme commits and the check mark moves.

```bash
cat ~/.local/state/quickshell/color_source; echo
```

Expected: the clicked preset's id.

- [ ] **Step 7: Verify the polish-loop guard**

```bash
grep -i "polish" /tmp/qs.log || echo "NO POLISH LOOP"
```

Expected: `NO POLISH LOOP`. A `QQuickItem::polish() loop` warning names the offending file:line and must be fixed — it destabilises other panels' layouts, not just this one.

- [ ] **Step 8: Commit**

```bash
git add quickshell/shell/modules/settings/SchemesSubPage.qml \
        quickshell/shell/modules/settings/Content.qml \
        quickshell/shell/modules/settings/WallpaperStylePage.qml
git commit -m "settings: add the colour preset picker

A colour-source row switches between wallpaper and preset, and a sub-page
lists the 24 presets with live preview on hover. The scheme row greys out
under a preset, where it genuinely drives nothing."
```

---

### Task 8: Documentation

**Files:**
- Modify: `INDEX.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add the INDEX.md entry**

Add to the feature index and mark it ✅, following the existing row style. Record: 24 presets read from the installed caelestia package (not vendored), `setscheme` as the entrypoint, and that `color_source` gates whether `switchwall` generates colours at all.

- [ ] **Step 2: Update CLAUDE.md**

Two additions. In the Commands section, next to `switchwall`:

```
**Apply a static colour preset** (bypasses the wallpaper entirely):
```
scripts/setscheme gruvbox/medium     # or: setscheme --list, setscheme dynamic
```
```

In the theming-pipeline section, note that `switchwall` exits before colour generation when `~/.local/state/quickshell/color_source` names a preset, and that `matugen json` renders the same templates from literal values — so there is exactly one template set, not one per source.

- [ ] **Step 3: Verify the doc claims are true**

```bash
setscheme --list | wc -l
setscheme dynamic && echo "dynamic OK"
```

Expected: `24`, then `dynamic OK`. Do not document a flag that does not work.

- [ ] **Step 4: Do NOT commit these two files**

`INDEX.md` and `CLAUDE.md` are both in `.gitignore` — they are local-only docs, not repo content. `git add` on either fails or silently does nothing.

```bash
git status --short
```

Expected: neither file appears. There is nothing to commit in this task; the edits are live locally and that is intended.

---

## Final verification

Run after all tasks. This is the spec's verification section end to end.

- [ ] **Full sweep**

```bash
cd ~/hyprland-config

# 1. Every preset applies cleanly
while IFS=$'\t' read -r pid modes; do
  setscheme "$pid" >/dev/null 2>&1 || echo "FAILED: $pid"
  grep -q '\$' ~/.config/kitty/theme.conf && echo "KITTY PLACEHOLDER LEFT: $pid"
done < <(scripts/lib/preset-palette.py list)
echo "sweep done"

# 2. Both fallback paths
echo light > ~/.local/state/quickshell/color_mode
setscheme dracula/medium          # dark-only from light
echo dark > ~/.local/state/quickshell/color_mode
setscheme catppuccin/latte        # light-only from dark

# 3. Wallpaper independence
setscheme gruvbox/medium
md5sum ~/.local/state/quickshell/colors.json > /tmp/final.md5
switchwall "$(find ~/wallpaper -type f | head -1)"
md5sum -c /tmp/final.md5 && echo "WALLPAPER INDEPENDENCE OK"

# 4. Back to dynamic
setscheme dynamic
md5sum -c /tmp/final.md5 2>&1 | grep -q FAILED && echo "DYNAMIC RESTORED"

# 5. Shell health
pkill -x qs; (qs -n -c shell > /tmp/qs.log 2>&1 &) ; sleep 4
grep -c "Configuration Loaded" /tmp/qs.log
grep -iE "error|polish|non-existent" /tmp/qs.log || echo "SHELL CLEAN"
```

Expected: `sweep done` with no `FAILED` or `KITTY PLACEHOLDER LEFT` lines, both fallbacks succeeding with a printed mode-substitution notice, `WALLPAPER INDEPENDENCE OK`, `DYNAMIC RESTORED`, and `SHELL CLEAN`.
