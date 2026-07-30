# Settings panel — the remaining mock rows

**Date:** 2026-07-31
**Status:** approved, not yet implemented

Wires 12 of the settings panel's 14 remaining mock rows to real behaviour. Two rows
stay mock on purpose; both are blocked on work that isn't settings work.

## Background

`modules/settings/` renders a row's label in `Colors.error` unless it carries
`live: true`, so the panel is its own progress board. Fourteen rows are still red:

| File | Row |
| --- | --- |
| `AudioPage.qml` | Allow over 100% · Show volume OSD · Dismiss after · Position |
| `PanelsPage.qml` | Fuzzy matching · Quick toggles · Close when settings opens |
| `ServicesPage.qml` | Popup position |
| `UpdatesPage.qml` | Notify when updates land · Show count in the bar · Terminal used for upgrades |
| `WallpaperStylePage.qml` | Display wallpaper · Interface font · Monospace font |

INDEX.md grouped these as "needs new behaviour" (10) / "deeper than a key" (4) /
"quick toggles" (1). An audit against the code found that grouping pessimistic —
several are near-trivial, and one is deeper than recorded.

## Scope

**In scope — 12 rows.** Everything above except the two named below.

**Out of scope — 2 rows.** Each needs a subsystem built before settings can expose
anything, so each stays red with an INDEX.md note naming its blocker:

- **Terminal used for upgrades** — `Updates.qml` only *checks* for updates. There is
  no upgrade action at all, so the row has nothing behind it. Blocked on: an upgrade
  runner.
- **Interface font** — needs shell-wide text styling, i.e. the shared `StyledText`
  tier of `review/comparison.md` #33, still unported. Blocked on: #33.

## Config keys

Eleven new keys, all in **existing** groups (`audio`, `notifications`, `launcher`,
`sidebar`, `updates`, `appearance`, `wallpaper`).

No new group means **no new `property alias`** — CLAUDE.md's alias trap (a missing
alias is a silent runtime `TypeError`, not a load failure) does not apply here.

Keys stay **flat within their group** (`audio.osdEnabled`, not `audio.osd.enabled`)
to avoid introducing a nested `JsonObject` and the alias question with it.

| Key | Type | Default | Row |
| --- | --- | --- | --- |
| `audio.allowBoost` | bool | `false` | Allow over 100% |
| `audio.osdEnabled` | bool | `true` | Show volume OSD |
| `audio.osdTimeout` | int (ms) | `1500` | Dismiss after |
| `audio.osdEdge` | string | `"right"` | Position |
| `notifications.popupPosition` | string | `"top-right"` | Popup position |
| `launcher.fuzzy` | bool | `true` | Fuzzy matching |
| `sidebar.closeOnSettings` | bool | `true` | Close when settings opens |
| `updates.notify` | bool | `true` | Notify when updates land |
| `updates.showInBar` | bool | `false` | Show count in the bar |
| `appearance.fontMono` | string | `"JetBrainsMono Nerd Font"` | Monospace font |
| `wallpaper.display` | bool | `true` | Display wallpaper |

Defaults preserve today's behaviour, so an existing `config.json` that predates these
keys behaves identically.

Both string-valued keys carry the repo's required trailing value comment:

```qml
property string osdEdge: "right"            // "right" | "left"
property string popupPosition: "top-right"  // "top-right" | "top-left" | "bottom-right" | "bottom-left"
```

## Design

### 1. Config plumbing (4 rows)

- **Show volume OSD** — `audio.osdEnabled` gates `VolumeOsd`'s `visible`.
- **Dismiss after** — `audio.osdTimeout` replaces the hardcoded
  `hideTimer.interval: 1500` at `VolumeOsd.qml:72`.
- **Close when settings opens** — one `Connections` block on `SettingsState.open`
  setting `SidebarRightState.open = false`, gated on `sidebar.closeOnSettings`.

  `SidebarRightState`'s `open()` / `close()` live **inside its `IpcHandler`** and are
  not callable as `SidebarRightState.close()`. Its public surface is the `open`
  property, `toggle()`, and the `ScreenOwner.claim(root)` pairing used when opening.
- **Allow over 100%** — `Audio.qml:74` clamps to `Math.min(1, …)`. The cap becomes
  `Config.audio.allowBoost ? 1.5 : 1`, applied to both `setVolume` and
  `setSourceVolume` so the mic keeps the same convention.

  **Audit required:** any slider bound `to: 1` cannot reach a raised cap, which would
  leave the setting dead. Check `VolumeOsdContent` and `AudioPage`'s volume rows and
  raise their ranges to match.

### 2. Fuzzy matching — one edit, not four

`services/Fuzzy.qml` is already a thin wrapper over the vendored `fuzzysort.js`, and
all four consumers (`Apps`, `Commands`, `Wallpapers`, `Cliphist`) call it the same way:

```qml
Fuzzy.go(query, list, { key: "name", all: true }).map(r => r.obj)
```

So the opt-out lives **inside `Fuzzy.go`**, not at the call sites. When
`Config.launcher.fuzzy` is false it does a case-insensitive substring filter on
`options.key`, preserving the list's original order, and returns `{obj}`-shaped
results so the wrapper's contract is unchanged and no consumer needs editing.

`Cliphist` keys on `"text"` while the rest key on `"name"`; reading the key from
`options` handles both.

### 3. Volume OSD edge

`VolumeOsd` is **not** a floating pill — it is a right-edge drawer, flush at
`restingMargin: 0`, with square right corners and two `Corner` fillets bridging into
the screen edge, and it is the third member of `RightEdgeStack`'s fixed
`["sidebar", "session", "volume"]` order. Free positioning would mean abandoning that
idiom. The row therefore offers the two positions the drawer actually supports.

Mirroring for `osdEdge === "left"`:

| Right (today) | Left |
| --- | --- |
| `anchors.right` / `anchors.rightMargin` | `anchors.left` / `anchors.leftMargin` |
| `topRightRadius: 0`, `bottomRightRadius: 0` | `topLeftRadius: 0`, `bottomLeftRadius: 0` |
| `Corner { corner: "bottomRight" }` (above) | `corner: "bottomLeft"` |
| `Corner { corner: "topRight" }` (below) | `corner: "topLeft"` |

`RightEdgeStack.register` is called **only when `osdEdge === "right"`**. On the left
the OSD has no stackmates, so `stackOffset` stays 0 and the singleton keeps its
right-edge-only contract. Deregister on switching to left so a stale entry can't keep
pushing nothing.

### 4. Toast position

`NotifPopups`' `PanelWindow` already spans the whole screen (all four layershell
anchors true); only the inner `stack` `Item` is positioned. So this is four anchor
lines plus one list property:

| Position | `stack` anchors | `ListView.verticalLayoutDirection` |
| --- | --- | --- |
| `top-right` | `top` + `right` | `TopToBottom` |
| `top-left` | `top` + `left` | `TopToBottom` |
| `bottom-right` | `bottom` + `right` | `BottomToTop` |
| `bottom-left` | `bottom` + `left` | `BottomToTop` |

`BottomToTop` on the bottom positions keeps the newest toast nearest the screen edge.

Two things deliberately need **no** change:

- **Swipe-to-dismiss** is already symmetric — `ToastCard.qml:51` tests
  `Math.abs(card.x)`, so it works in both directions regardless of side.
- **The mask** is `mask: Region { item: stack }`, a static reference. Repositioning
  `stack` does not make it conditional, so CLAUDE.md's conditional-mask trap (which
  silently breaks rendering, not just input) is not triggered.

### 5. Updates — notify and bar count

**Notify.** `Updates.qml` already tracks `total`. It gains a `_lastNotifiedTotal`;
when a background check settles with `total` greater than that, and `updates.notify`
is on, it fires:

```qml
Quickshell.execDetached(["notify-send", "-a", "quickshell", …])
```

reusing the pattern already proven at `SessionActionButton.qml:33`. Notifying only on
an *increase* means a routine re-check that finds the same pending updates stays quiet.

**Bar count.** A new `modules/bar/UpdatesIndicator.qml`, modelled on the existing
`NotifIndicator.qml`, added to `Bar.qml`'s right-side `RowLayout` beside it. Visible
on `updates.showInBar && Updates.total > 0`. Clicking opens the settings Updates page
through the existing `settings page <n>` state.

**Singleton trap:** `Updates` is `pragma Singleton`, so it only exists once something
references it — `shell.qml`'s `Component.onCompleted` already pokes it awake with
`Updates.backgroundChecking = true`. The bar indicator adds a second consumer but
does not remove the need for that poke, since the indicator is hidden when
`showInBar` is false.

### 6. Quick toggles → sidebar edit mode

`QuickTogglesRow.editMode` is a plain local property, so settings cannot reach it.
It lifts into `SidebarRightState` as `quickTogglesEditMode`; `QuickTogglesRow` binds
to the singleton instead of owning the value, and its own edit button writes through
to it.

The settings row stops pretending to hold a value and becomes a navigation action:

```qml
SettingsState.open = false;
ScreenOwner.claim(SidebarRightState);
SidebarRightState.open = true;
SidebarRightState.quickTogglesEditMode = true;
```

Closing settings *first* means the action cannot fight the "Close when settings opens"
toggle from §1. The `ScreenOwner.claim` call is what pins the sidebar to the right
monitor, matching what `SidebarRightState`'s own IPC `open()` does.

This matches the 2026-07-27 decision recorded in INDEX.md: settings may drive
singleton-backed state by binding to the singleton, never by writing its file.

### 7. Monospace font

Five sites hardcode `"JetBrainsMono Nerd Font"` and become `Config.appearance.fontMono`:

- `modules/sidebarRight/SystemHeaderCard.qml:24`
- `modules/settings/AboutPage.qml:34`
- `modules/bar/NotifIndicator.qml:27`
- `modules/dashboard/dash/UserCard.qml:70`
- `modules/sidebarRight/NotificationsCard.qml:35`

`components/MaterialIcon.qml`'s `"Material Symbols Rounded"` is **not** included — it
is an icon font, not a text font.

To make the `SelectPill` honest rather than a hardcoded guess, a new
`services/Fonts.qml` shells `fc-list : family spacing=100` through `Process` +
`StdioCollector`, following the `Wallpapers.qml` / `Recordings.qml` pattern
(including `onExited` cleanup), and exposes a deduplicated sorted family list.

**Caveat, to be stated in the row's subtext:** three of those five sites render Nerd
Font glyphs (the distro logo in `SystemHeaderCard`, and `NotifIndicator` /
`UserCard`). Choosing a non-Nerd monospace font blanks them. The row warns rather
than filtering the list, since detecting Nerd Font coverage from `fc-list` is not
reliable.

Related trap (CLAUDE.md): private-use-area glyph characters are stripped when a file
is written wholesale. Any edit touching `SysInfo.qml`-style glyph literals must be a
targeted `Edit`, never a whole-file `Write`, and glyphs stay written as `"\uf303"`
escapes.

### 8. Display wallpaper

Three parts, one of them outside the shell:

1. **`scripts/switchwall`** reads `wallpaper.display` through its existing `cfg`
   jq helper (the same mechanism already used for the `theming.*` group) and skips
   the mpvpaper spawn when false. This keeps `config.json` the single source of
   truth rather than adding a second state file.
2. **The settings toggle** applies the change live, so the row takes effect without
   waiting for the next `switchwall` run:
   - **off** → `pkill -f mpvpaper`
   - **on** → `switchwall --preview "$(cat ~/.local/state/quickshell/current_wallpaper)"`

   `--preview` already means exactly "set the wallpaper and exit before any colour
   generation", so re-displaying costs nothing extra and needs no new switchwall mode.
   Crucially it keeps the mpvpaper invocation (`MPV_OPTS`, derived monitor names) in
   `switchwall` alone rather than duplicating it into QML as a second source of truth.
3. **`matugen/templates/hyprland/`** gains a `misc:background_color` line, so the
   bare desktop shows the wallpaper-derived background colour instead of Hyprland's
   default. Theming still runs off the last wallpaper, so the desktop stays coherent
   with the shell even with no wallpaper displayed.

`hypr/general.lua`'s `misc` block does not currently set `background_color`, and
`hypr/colors.lua` is generated and loads *after* `general`, so the generated value
wins without a conflict.

## Verification

No test suite exists. Per CLAUDE.md, "done" means lint + restart + exercise live —
never a code read.

**Per touched file:** Qt 6 qmllint (`/usr/lib/qt6/bin/qmllint`, not `/usr/bin/qmllint`,
which is Qt 5's), with the documented disabled categories.

**Per change:** `pkill -x qs; qs -n -c shell`, then count `Configuration Loaded` in
the log to prove the reload happened. Hot reload is not trustworthy for verification.
A clean lint does not prove signal wiring — the runtime is what rejects a bad handler.

**Per row, live:**

| Row | How it is exercised |
| --- | --- |
| Allow over 100% | `wpctl get-volume @DEFAULT_SINK@` past unity |
| Show volume OSD / Dismiss after | `wpctl set-volume`, watch the drawer and time the hide |
| OSD position | `hyprctl layers -j` confirms the surface's edge |
| Popup position | real `notify-send` toasts in all four corners |
| Fuzzy matching | launcher query matching an app by subsequence vs substring |
| Quick toggles | click the row, confirm the sidebar opens in edit mode |
| Close when settings opens | open settings with the sidebar open |
| Updates notify / bar count | drive `Updates.total` and watch for the toast and pill |
| Monospace font | change the family, screenshot an affected card |
| Display wallpaper | `pgrep mpvpaper` plus a `grim` screenshot of the bare desktop |

Overlay panels only render on the Hyprland-**focused** monitor, so check
`hyprctl monitors -j | jq '.[] | {name, focused}'` before reading a blank screenshot
as a failure.

## Outcome

The settings panel goes from **14 red rows to 2**. INDEX.md's "Settings panel" entry
is rewritten to name the two remaining blockers rather than listing fourteen rows.
