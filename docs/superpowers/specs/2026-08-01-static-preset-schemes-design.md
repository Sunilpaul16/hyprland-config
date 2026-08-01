# Static preset colour schemes

**Date:** 2026-08-01
**Status:** approved, not yet implemented

Adds 24 hand-written colour schemes (catppuccin, gruvbox, dracula, nord, rosepine,
everforest, …) as an alternative to the wallpaper-derived palette. Picking one themes
the whole desktop — shell, Hyprland, hyprlock, GTK3/4, btop, kitty — and wallpaper
changes stop touching colours until the user switches back to `dynamic`.

## Background

Today every colour in this desktop derives from the wallpaper. `switchwall` scores a
seed colour out of the image, matugen expands it into the M3 roles, and a separate
materialyoucolor pass produces kitty's 16-colour ANSI palette. `theming.scheme`
selects which of matugen's nine M3 variants does the expansion.

Caelestia's shell (`~/shell`) has a second axis this repo lacks. Its scheme state
carries four fields — `name`, `flavour`, `mode`, `variant` — where `variant` is the
M3 recipe (the direct analogue of `theming.scheme`) and `name` chooses between
`dynamic` (wallpaper-derived) and a static preset. Static presets are plain text
files shipped inside the `caelestia` Python package, one `roleName hexcolour` per
line, and involve no colour generation at all.

This design ports that `name` axis.

## Research findings

Everything below was verified against the installed artifacts, not assumed.

### matugen accepts a fixed palette

The initial assumption — that a static palette would need a hand-written template
renderer — is **wrong**. matugen 4.1.0 (`/usr/bin/matugen`) has a `json` subcommand
that renders templates from literal values:

```
matugen json <PATH>
```

Verified by passthrough: injecting `#00ff00` into a dumped palette and re-feeding it
returns `#00ff00` verbatim rather than re-deriving from a seed. Bare 6-digit hex with
no leading `#` is accepted and normalised, which is exactly the preset file format.

Required input schema (note the `color` wrapper at the leaf):

```json
{"colors": {"<role>": {"default": {"color": "<hex>"},
                       "light":   {"color": "<hex>"},
                       "dark":    {"color": "<hex>"}}}}
```

**Consequence: no renderer to write, and no second template set.** Presets render
through `matugen/templates/` unchanged, so preset output and dynamic output cannot
drift.

### The templates need 34 roles

The six templates contain 221 placeholders in exactly one grammar,
`{{colors.<role>.<variant>.<format>}}`, referencing 34 distinct roles:

```
background error error_container inverse_on_surface inverse_primary inverse_surface
on_background on_error on_error_container on_primary on_primary_container
on_primary_fixed on_secondary_container on_surface on_surface_variant outline
outline_variant primary primary_container primary_fixed primary_fixed_dim secondary
secondary_container secondary_fixed_dim surface surface_container
surface_container_high surface_container_highest surface_container_low
surface_container_lowest surface_variant tertiary tertiary_container
tertiary_fixed_dim
```

Value formats in use: `hex` (leading `#`, 6 lowercase digits), `hex_stripped` (same
without `#`), and `red`/`green`/`blue` (0–255 decimal integers). No non-colour
placeholders exist anywhere.

`gtk-4.0/gtk.css` is the only template referencing both `light.*` and `dark.*`;
`hyprland/colors.lua` and `hyprlock/colors.conf` each pin one `surface.dark`
reference regardless of mode.

### The preset corpus is complete and clean

`/usr/lib/python3.*/site-packages/caelestia/data/schemes/` — 14 schemes, 24
scheme+flavour pairs, 29 files (22 dark, 7 light).

- **All 34 required roles are present in all 29 files.** Zero exceptions.
- **All 16 `term0`–`term15` are present in all 29 files.** Zero exceptions.
- Every value matches `^[0-9a-fA-F]{6}$`. No blank lines, no duplicate keys, no CRLF,
  no malformed splits.

Mode availability is irregular and must not be assumed:

| Availability | Flavours |
| --- | --- |
| Both modes | caelestia/default, everforest/medium, gruvbox/{hard,medium,soft} |
| Light only | catppuccin/latte, rosepine/dawn |
| Dark only | the other 17 |

`catppuccin` is internally asymmetric: three dark flavours plus one light flavour,
with no flavour offering both.

**Two parser traps, both fixed at vendor time:**

1. **18 of 29 files have no trailing newline.** Any parse doing
   `content.split("\n")[:-1]` silently drops the final key (`onSuccessContainer`)
   from those files.
2. **Hex case is inconsistent** across and within files — 9 files are largely
   uppercase, 2 mixed, and `onSuccessContainer` is uppercase in all 29.

Because the corpus is vendored, both are normalised once during the copy — every
file gains a trailing newline and every value is lowercased. The parser still reads
line-wise and lowercases anyway; that costs nothing and keeps it correct if a file
is ever hand-edited or re-copied from upstream.

### Kitty needs no generator

`switchwall:237-242` is a generator-agnostic text filter. It consumes any stream of
`$name: #RRGGBB;` lines and rewrites `matugen/colorgen/terminal/kitty-theme.conf`
by `sed`. A preset can emit its own stream and produce an identical theme file with
materialyoucolor never invoked.

The template requires **33** names, not 16 — `term0`–`term15` plus `primary,
primaryContainer, secondary, secondaryContainer, onSecondaryContainer, tertiary,
tertiaryContainer, error, errorContainer, onPrimary, onPrimaryContainer, onSecondary,
onTertiary, onTertiaryContainer, onError, onErrorContainer, outlineVariant`. All 33
exist in every preset file. A missing name is left in the output **literally** as
`color255 #$primary #`, which kitty fails to parse — so this must be validated, not
trusted.

### switchwall has a latent ordering bug

`switchwall:7-9` derives monitor names from `hypr/general.lua` and `:116` requires
`mpvpaper`, both **unconditionally, before argument parsing**. So `--colors-preview`
and `--noswitch` already `exit 1` if `general.lua` is unreadable or reformatted,
despite setting no wallpaper. This design fixes it as a side effect of the extraction
below, rather than inheriting it into a second entrypoint.

## Scope

**In scope.** All 24 scheme/flavour combinations, **vendored into this repo** at
`matugen/schemes/`, themed across every surface `switchwall` themes today. A
settings-panel picker with live preview. Wallpaper independence.

**Out of scope.**

- **A launcher action prefix.** This repo has no action-prefix system, and building
  one is its own feature.
- **User-authored presets.** No mechanism for dropping in custom palettes.
- **The `caelestia/default` scheme's 10 extra keys** (`primaryDim`, `errorDim`, the
  camelCase `*PaletteKeyColor` block). Nothing in this repo's templates reads them.

## Config keys

Two new keys in the **existing** `theming` group. No new group means no new
`property alias`, so CLAUDE.md's alias trap does not apply.

```qml
property string source: "dynamic"   // "dynamic" | "preset"
property string preset: ""          // "<scheme>/<flavour>", e.g. "gruvbox/medium"
```

`theming.scheme` is unchanged and applies only while `source` is `dynamic`.

One new state file, `~/.local/state/quickshell/color_source`, holding either
`dynamic` or the preset id. `switchwall` reads this file rather than parsing
`config.json`, matching how it already reads `color_mode`.

## Architecture

### `scripts/lib/apply-colors.sh` (new)

The colour half of `switchwall`, extracted so both entrypoints share one
implementation:

- `cfg` / `cfgbool` jq helpers
- the kitty `sed` pipeline and its `theming.terminalOpacity` tail
- `gsettings` light/dark
- the reload trio: `hyprctl reload`, `pkill -SIGUSR1 -x kitty`, `nautilus -q`

Extraction is behaviour-preserving. `switchwall` sources it and keeps its wallpaper
logic; the monitor derivation and `mpvpaper` preflight move behind the wallpaper
branch.

### `scripts/setscheme <scheme>/<flavour>` (new)

Symlinked into `~/.local/bin/` alongside the other three scripts.

1. **Locate the corpus** — `matugen/schemes/` inside this repo, resolved relative to
   the script's own real path so the symlink into `~/.local/bin` resolves correctly.
2. **Resolve the mode** — read `color_mode`; if the preset has no file for it, use
   the mode it does have and print which.
3. **Parse** — line-wise, lowercase values, into a `roleName -> hex` map.
4. **Validate** — all 34 template roles and all 33 kitty names present, or abort
   before writing anything.
5. **Build matugen JSON** — camelCase → snake_case, `default`/`light`/`dark` all set
   to the same value.
6. **`matugen json <tmpfile>`** — renders all six templates.
7. **Kitty** — emit the 33 names as `$name: #hex;`, pipe through the shared filter.
8. **`gsettings`** from the resolved mode.
9. **State** — write `color_mode` and `color_source`. Never write
   `current_wallpaper`.
10. **Reload.**

Steps 6–9 run only after step 4 passes, so a rejected preset leaves the existing
theme fully intact.

### `switchwall` (modified)

One early branch: if `color_source` is not `dynamic`, set the wallpaper and exit
before any colour generation. No new flags — returning to wallpaper-derived colours
is `setscheme dynamic`, which writes `color_source` and then delegates to
`switchwall --noswitch`, keeping one entrypoint per concern.

### `services/Schemes.qml` (new)

`Process` + `StdioCollector`, following `Wallpapers.qml`. One shot to locate the
corpus and list `scheme/flavour/mode`; reads an individual file on demand for
swatches and preview. No timers, so it needs no `shell.qml` wake-up poke — it is
instantiated by the settings sub-page opening.

### `services/ColorsLoader.qml` (modified)

Add `previewPalette(map)` beside the existing `preview(path)`. Preset preview needs
**no subprocess** — the colours are already on disk, so it sets `previewing = true`
and calls the existing `applyColors()` directly. Instant, versus the second-or-two
matugen round trip. `clearPreview()` is unchanged and reverts both kinds.

### Settings UI

- `WallpaperStylePage.qml` — a "Colour source" `SelectMenu` (Wallpaper / Preset)
  above the existing Scheme row. The Scheme row greys out while a preset is active,
  because it genuinely drives nothing then.
- `SchemesSubPage.qml` (new) — registered in `Content.qml`'s `subPageModel` beside
  `"wallpapers"`, inheriting `PageBase.isSubPage`'s back arrow and Escape handling.
  24 rows, each a two-tone swatch (surface circle with a primary half-overlay) plus
  scheme and flavour labels, and a check on the active row.
- Highlighting a row previews it live; leaving the sub-page by any route reverts.
- All new rows carry `live: true`.

## Data flow

```
preset .txt ──parse──> roleName->hex map
                          ├──> matugen JSON ──> matugen json ──> 6 templates
                          │                                       ├─ colors.json ──watch──> shell
                          │                                       ├─ colors.lua ──hyprctl reload
                          │                                       ├─ hyprlock, gtk3, gtk4, btop
                          └──> $name: #hex stream ──sed──> kitty/theme.conf ──SIGUSR1
```

Preview is a separate, shorter path: QML reads the `.txt`, builds the 14 shell keys,
and mutates `Colors` in place. Nothing is written to disk and no other app is
touched, so revert is a re-read of the real `colors.json`.

## Accepted consequences

**GTK4 loses its light/dark split under a preset.** Its `@media` blocks are fed from
`light.*` and `dark.*`; a single-mode preset renders both nearly identically. Since
`gsettings` pins the mode, apps still select the correct block — but three hardcoded
green "success" colours in the template will be wrong for one polarity. Judged not
worth a second template set.

**Silent mode fallback.** Selecting a dark-only preset in light mode quietly applies
dark, so the light/dark toggle can appear inert. This matches caelestia and avoids
either an error path or greying out 17 of 24 rows.

## Risks

**GPL-3.0 obligations.** The corpus is vendored, so its licence now applies to this
repo. Caelestia ships the GPLv3 text and no other licence, with no per-file header
and no named copyright holder in the installed artifacts. `matugen/schemes/LICENSE`
carries the licence text and `matugen/schemes/PROVENANCE.md` records the source,
version and the normalisation applied. This repo currently declares no licence of
its own; if one is ever added it must be GPLv3-compatible, which is a real
constraint rather than a formality.

**Upstream palette licences are unaudited.** Several of these palettes (Catppuccin,
Gruvbox, Nord, Dracula, Rosé Pine, Tokyo Night, Everforest, Solarized) derive from
theme projects with their own licences, mostly MIT but varying. Caelestia ships no
notices for them and this design does not audit them. Noted so the gap is a known
one rather than an assumed absence.

**The corpus is now a fork.** Vendored files no longer track caelestia upstream. New
schemes added there will not appear here without a manual re-copy. This is the
accepted cost of not depending on an external package.

**`sed`-based kitty rewriting is positional.** The existing filter relies on a
trailing ` #` anchor to stop `$term1` matching inside `$term15`. Reused as-is, not
modified, but it constrains what a preset stream may contain.

## Verification

No test suite exists; this follows the repo's own convention of lint, reload, and
exercise live at the system level.

1. Qt 6 `qmllint` on every touched QML file.
2. Apply `gruvbox/medium` and **diff each of the six generated outputs against the
   source `.txt` values** — the proof is matching hex in `colors.lua`, both
   `gtk.css`, the btop theme, `colors.json` and `hyprlock/colors.conf`, not a zero
   exit code.
3. `grep '\$' kitty/theme.conf` — any surviving placeholder means a missing role.
4. Restart the shell; count `Configuration Loaded`.
5. **Checksum `colors.json`, change the wallpaper, checksum again — must be
   identical.** This is the core new behaviour.
6. Switch back to `dynamic`; confirm colours regenerate from the wallpaper.
7. Exercise both fallback paths: `dracula/medium` (dark-only) from light mode, and
   `catppuccin/latte` (light-only) from dark mode.
8. Arrow through the sub-page confirming live repaint, then Escape and confirm the
   palette reverts exactly.
9. Confirm `switchwall --colors-preview` still works with `general.lua` temporarily
   unreadable, proving the ordering fix.

## Follow-ups

- `INDEX.md` entry, per the repo convention that it is the living status board.
- A `review/comparison.md` row if this is judged a caelestia port worth tracking
  there; no existing row covers it.
