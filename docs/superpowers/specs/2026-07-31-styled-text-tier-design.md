# StyledText tier — making the font settings real

Ports the `StyledText` half of `review/comparison.md` #33, and with it converts the
settings panel's last two mock rows into working controls.

## Problem

The settings panel shows "Interface font: Rubik" and "Monospace font: JetBrainsMono
Nerd Font". Both are invented labels driving nothing, and both render red under the
panel's `live: false` convention.

They are not blocked on a missing config key. `Config.appearance.fontMono` exists and
has five consumers. They are blocked on two facts:

1. **All five `fontMono` consumers draw Nerd Font glyphs, not text** — the About page's
   distro logo, the bar's notification bell, and the sidebar/dashboard header glyphs.
   Qt resolves a glyph from whichever font provides it regardless of the requested
   family, so the key has no observable effect. Measured 2026-07-31: set to VT323, the
   glyph rendered pixel-identically. The key is misnamed — it is a *glyph* font.
2. **No text in the shell requests a font at all.** All 182 `Text {}` blocks across 71
   files inherit Qt's default (`Noto Sans`, via fontconfig). There is nowhere for an
   "Interface font" setting to attach.

There is no global escape hatch. Quickshell exposes no font setter (no match in its
source or `qmltypes`), and plain `Item`/`Text` do not participate in Qt's font
inheritance chain — only `Control`-derived types do. Every text site must ask for the
family itself.

## Design

### 1. The component

`quickshell/shell/components/StyledText.qml` — a `Text` subclass carrying two defaults:

```qml
Text {
    font.family: Config.appearance.fontInterface
    color: Colors.text
}
```

Deliberately minimal. No size or weight ladder: 170 of the 182 sites already cluster on
six pixel sizes, but mapping each to a named step is a judgment call per site, and
bundling a visual-consistency change into font plumbing would make both harder to
verify. Tokenising the size scale stays a separate, later change.

`renderType` is left at Qt's default. caelestia's `StyledText` sets
`Text.NativeRendering`, which sharpens small text but does not survive rotation — this
box drives DP-2 at `transform=3`, so the default stays.

`MaterialIcon` continues to extend `Text` directly, **not** `StyledText`. It sets its
own family (`Material Symbols Rounded`) and must never inherit `fontInterface`.

### 2. Config schema

In the existing `appearance` group:

- `fontMono` → **`fontGlyph`**, same default `"JetBrainsMono Nerd Font"`. A rename, not
  a new key: the old name described something the key never did.
- **`fontInterface`** added, defaulting to `"Noto Sans"` — what the shell already renders
  today, so an absent key changes nothing.

Both are scalars in an existing group, so neither needs a `property alias` (CLAUDE.md's
alias rule applies to new *groups*).

The rename means migrating the live `~/.config/quickshell/config.json`. Rewrite it with
`cat tmp > config.json` to preserve the inode — a `jq > tmp && mv` breaks `FileView`'s
watch and the shell later writes its stale in-memory copy back over the edit.

Both values are validated against `Qt.fontFamilies()` on load, falling back to the
default when the named family is absent. Without this, a hand-edited config naming an
uninstalled family renders in Qt's default with no indication why.

### 3. Migration

182 sites across 71 files. Per site:

- `Text {` → `StyledText {`
- add the `components` import where absent
- delete `color: Colors.text` where it is now redundant (68 sites)

Everything else is left exactly as written: the 67 `color: Colors.textMuted` sites, all
conditional colours, all `font.pixelSize`, and all 46 `font.bold`. This pass changes
family plumbing only. No visual change is intended beyond the family itself.

Sites needing judgment rather than a blind swap:

- The five glyph consumers move to `fontGlyph`, not `fontInterface`.
- `sidebarRight/NotificationsCard.qml:35` conditionally selects between the glyph font
  and `Qt.application.font.family`; its condition must be preserved.

### 4. The settings rows

Both on the Wallpaper & Style page, both gaining `live: true`:

- **Interface font** → `fontInterface`. A curated list of ten families verified present
  on this box: Noto Sans, Rubik, Adwaita Sans, Open Sans, Space Grotesk, Readex Pro,
  Carlito, DejaVu Sans, Liberation Sans, VT323. Curated because no reliable filter
  distinguishes a UI-suitable family from the 695 installed.
- **Glyph font** (relabelled from "Monospace font") → `fontGlyph`. Enumerated at runtime
  from `Qt.fontFamilies()` filtered on `/Nerd Font$/` — an unambiguous filter, yielding
  three here and growing on its own as fonts are installed.

Both use the existing `SelectMenu` unmodified. Its `ColumnLayout`+`Repeater` in a
`PopupWindow` has no scrolling and no height cap, which is fine at ten and three
entries and is why the interface list is curated rather than exhaustive. Each menu row
renders its label in its own face, so the menu previews itself.

## Verification

A clean qmllint is not sufficient here and a code read is not either.

1. Qt 6 qmllint over the touched tree (`/usr/lib/qt6/bin/qmllint`, not `/usr/bin/qmllint`).
2. `pkill -x qs; qs -n -c shell`, and count `Configuration Loaded`. With 71 files touched
   this is the real gate — a typo'd property rejects the entire config, and hot reload is
   not reliable enough to verify against.
3. Set `fontInterface` to VT323 and screenshot the bar, launcher and settings panel with
   `grim`. The family must visibly change. This is the exact test the current `fontMono`
   fails, and passing it is what makes the rows honest.
4. Confirm the glyph sites are *unaffected* by step 3 — they should still render their
   Nerd Font glyphs while surrounding text turns pixel-retro.

Screenshot the focused monitor: overlay panels only render on the Hyprland-focused
output, and a fullscreen game makes shell UI untestable entirely.

## Out of scope

- A size/weight token ladder (noted above; separate change).
- The other two thirds of comparison.md #33 — the shared `Switch`, and moving
  `MaterialIcon` out of `sidebarRight/`. `MaterialIcon` already lives in `components/`;
  the `Switch` duplication is untouched here.
- The "Terminal used for upgrades" row, the panel's remaining mock row, which is blocked
  on there being no upgrade runner at all.
