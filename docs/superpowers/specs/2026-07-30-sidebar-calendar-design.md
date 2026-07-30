# Sidebar calendar card

## Problem

The right sidebar (`SUPER+A`) ends at the notifications card, which takes all the
column's leftover height via `Layout.fillHeight`. On an empty notification list that
space is the dino watermark and nothing else — a large dead area at the bottom of the
panel.

A month calendar already exists in this repo, but only in the dashboard overlay
(`SUPER+D`), as a 165-line `CalendarCard` component defined inline in
`modules/dashboard/DashTab.qml:138-304`. Reaching it means opening a separate overlay.

## Goal

A calendar card pinned to the bottom of the right sidebar, below notifications,
collapsible to a one-line date summary — following end-4's `BottomWidgetGroup.qml`
placement and geometry — without producing a second copy of the month-grid logic.

## Reference

end-4's `modules/ii/sidebarRight/`:

- `SidebarRightContent.qml:100-109` stacks notifications (`Layout.fillHeight: true`)
  then `BottomWidgetGroup` (`fillHeight: false`, `preferredHeight: implicitHeight`).
- `BottomWidgetGroup.qml` is a fixed 350px card holding a 3-tab nav rail
  (Calendar / To Do / Timer) plus a collapse chevron. Collapsed it reads
  `Thu, Jul 30 • 3 tasks`. Tab and collapsed state persist.
- `calendar/CalendarDayButton.qml` is 38x38 at `rounding.small` — rounded squares, not
  circles — with spacing 5, and the weekday header row reuses that same button, bolded
  and disabled.

**Scoped out of this spec:** the nav rail, and the To Do / Timer tabs. Each needs its
own service and storage, and a rail with a single button is clutter. Adding the rail
later does not require redoing this work.

**Not ported:** end-4's `calendar_layout.js` (113 lines of hand-rolled month layout).
Qt's `MonthGrid` already backs the dashboard card and produces the same result.

## How `MonthGrid` actually sizes its cells

Measured at runtime, not read from a file — the on-disk
`/usr/lib/qt6/qml/QtQuick/Controls/Basic/MonthGrid.qml` shows a plain `Grid` positioner
and is **not what runs**. `MonthGrid` resolves to the qrc-embedded copy at
`qrc:/qt-project.org/imports/QtQuick/Controls/Basic/MonthGrid.qml`, whose behaviour
differs. Probe results at a control width of 400px:

| control | delegate width | pitch |
|---|---|---|
| `MonthGrid` (`spacing: 4`) | 53.71 = `(400 - 6*4) / 7` | 57.71 |
| `DayOfWeekRow` (`spacing: 6`) | 52 | 58 |

Both controls **stretch their delegates to fill the available width**. Two consequences
that shape the design:

1. **Column alignment is already correct** and needs no fixing. Differing `spacing`
   values drift the two pitches by ~0.9px at the last column — invisible.
2. **A day cell is wide and short.** Width stretches to ~54px while `implicitHeight`
   stays 26, so `DashTab.qml`'s `radius: 13` marker renders as a **stadium pill**, not
   the circle its author presumably intended.

An earlier draft of this spec asserted a header-misalignment bug based on the on-disk
file. That was wrong; the screenshot and the probe both disprove it.

### Day marker

Because cells stretch, the marker cannot simply be the cell's own background. The
delegate is an `Item` at the cell's stretched width, holding a **centred `cellSize` x
`cellSize` marker** — which makes `dayRadius` honest (`cellSize / 2` is a real circle)
and matches end-4's square day buttons.

This changes the dashboard's existing look: its today marker goes from a wide stadium
pill to a 26px circle. Accepted deliberately.

Sizing follows from this too: the sidebar needs **no width arithmetic**. Cells stretch
to `(304 - 6*5) / 7 ≈ 39px` on their own. `cellSize` controls only row height and marker
size.

## Design

### `components/CalendarGrid.qml` (new)

The month grid alone. Draws no card chrome — no background, radius or border — so the
caller owns its own surface. Knows nothing about the sidebar or the dashboard.

| property | type | default | purpose |
|---|---|---|---|
| `cellSize` | int | 26 | row height and the centred marker's size; **not** cell width, which stretches |
| `cellSpacing` | int | 4 | passed to both `MonthGrid` and `DayOfWeekRow` |
| `dayRadius` | int | `Motion.rounding.small` | end-4's rounded squares; dashboard passes `cellSize / 2` for circles |
| `showTodayButton` | bool | true | sidebar sets false — its header carries the chevron instead |
| `headerLeftInset` | int | 0 | reserves room at the head of the nav row for a caller's own button |

Internal state: `property date viewDate: new Date()`, plus `viewMonth` / `viewYear` /
`onCurrentMonth` derived from it, as the existing card already has.

Behaviour ported verbatim from `DashTab.qml`'s `CalendarCard`:

- `‹` / `›` step the month.
- Clicking the month label jumps to today (no-op and no hover state when already on the
  current month).
- `WheelHandler` steps the month.
- Middle-click anywhere jumps to today.
- Today cell is filled `Colors.primary` with `Colors.background` text; weekends tint
  `Colors.primary`; out-of-month days drop to 0.35 opacity.

`implicitHeight` is computed from its own content so callers can size to it.

Two additions the current dashboard card does not have:

1. **`function goToToday()`** — public, so a container can reset the view.
2. **Midnight-correct highlight.** `model.today` is computed by the calendar model and
   will not re-evaluate while the component stays alive. The delegate instead compares
   its date against `readonly property string todayKey: Time.format("yyyy-MM-dd")` — one
   binding that changes at midnight. Do **not** bind delegates to `Time.date` directly:
   `Time.qml` runs `SystemClock.Seconds`, so that re-evaluates 42 delegates every second.

### `modules/sidebarRight/CalendarCard.qml` (new)

```
Rectangle
  radius: Motion.rounding.large     // matches NotificationsCard
  color: Colors.layer               // cards use layer, not panel
  clip: true                        // content must not spill during collapse
  implicitHeight: collapsed ? collapsedRow.implicitHeight
                            : expandedColumn.implicitHeight + 32
  Behavior on implicitHeight { NumberAnimation { Motion.smoothDuration / smoothEasing } }
```

**Expanded height is derived, not the 350 literal end-4 uses.** At `cellSize: 36` and
`cellSpacing: 5`, the grid is `36 * 6 + 5 * 5 = 241`, plus the ~26px weekday row, the
~26px nav row, two 8px column gaps and 32px of margins — about 341, near end-4's 350
without having to guess. Hardcoding a literal risks clipping the last week, and
`clip: true` would hide that it was happening.

`readonly property bool collapsed: Config.sidebar.calendarCollapsed`.

**Expanded:** chevron-down button at the header's left, then `CalendarGrid` with
`showTodayButton: false`, `cellSize: 36`, `cellSpacing: 5` and `headerLeftInset: 30`.

No width arithmetic is needed — cells stretch to `(304 - 30) / 7 ≈ 39px` on their own.
An earlier draft computed `cellSize` from the card's width; that both was unnecessary
and would have coupled height to width for no reason.

**Collapsed:** a single row, chevron-up plus `Time.dateStr` (already formatted
`"ddd, MMM d"`, giving `Thu, Jul 30`). No `• N tasks` — there is no todo service.

Cross-fade between the two rows follows end-4's approach: both are always present,
`opacity` driven by `collapsed`, `visible: opacity > 0`.

**Reset on open.** The sidebar is a `LazyLoader` that stays alive after first load, so
without this, navigating to December and closing leaves it on December next time:

```qml
Connections {
    target: SidebarRightState
    function onOpenChanged() { if (SidebarRightState.open) grid.goToToday() }
}
```

### `modules/sidebarRight/SidebarRightPanel.qml` (edit)

After `NotificationsCard` in the existing `ColumnLayout`, no new divider — the current
divider still marks the utility-cards boundary, and the 12px gap plus the card's own
`Colors.layer` fill separates it well enough:

```qml
CalendarCard {
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.preferredHeight: implicitHeight
}
```

`NotificationsCard` keeps `Layout.fillHeight: true` and `Layout.minimumHeight: 120`, so
the calendar takes its fixed height and notifications absorbs the remainder.

### `modules/dashboard/DashTab.qml` (edit)

`CalendarCard` collapses from 165 lines to its `Rectangle` chrome (which keeps its
`border.width: 1`, unlike the sidebar's) wrapping:

```qml
CalendarGrid { cellSize: 26; dayRadius: cellSize / 2 }
```

`dayRadius: cellSize / 2` gives a true circle on the centred 26x26 marker — a visible
change from the wide stadium pill this card renders today, accepted per the day-marker
section above. The `NavButton` component moves into `CalendarGrid` along with the header
it serves; check whether anything else in `DashTab.qml` still uses it before deleting it
there.

### `services/Config.qml` (edit)

One scalar added to the existing `sidebar` group. Per CLAUDE.md, adding to an existing
group needs no new `property alias` — only new *groups* do:

```qml
property JsonObject sidebar: JsonObject {
    property string noNotifsImage: ""
    property bool calendarCollapsed: false   // sidebar calendar card starts collapsed
}
```

`Config`, not `Persistent`: `Persistent.qml` deliberately resets on a fresh Hyprland
login, which is right for transient card visibility but wrong for a durable layout
preference.

## Known limitation

Below roughly 800px of screen height the column runs out of room — notifications shrinks
to its 120px floor and the stack then overflows the backdrop. Both monitors here are
2560x1440, so this cannot occur on current hardware. Deliberately not solved; no hiding
threshold is being added for a case that cannot happen.

## Verification

Per CLAUDE.md, a code read is not evidence.

1. **Lint** all five files with the Qt 6 command from CLAUDE.md (`/usr/lib/qt6/bin/qmllint`,
   not `/usr/bin/qmllint`).
2. **Restart** — `pkill -x qs; qs -n -c shell` — and count `Configuration Loaded` to
   prove the reload happened. A handler bound to a non-existent signal only fails at
   load, so a clean lint alone proves nothing about the `Connections` block.
3. **Sidebar** — `qs -c shell ipc call sidebarRight open`, then `grim` DP-2 (check
   `hyprctl monitors -j` for the focused one first; overlays only render there). Confirm:
   weekday headers sit over their columns, today is a filled pill, weekends tint,
   out-of-month days dim, and all six week rows are visible (nothing clipped at the
   bottom edge).
4. **Collapse** — ydotool-click the chevron, screenshot, confirm the one-line date row
   and that notifications reclaims the space. Restart the shell and confirm the state
   survived via `config.json`.
5. **Dashboard regression** — `qs -c shell ipc call dashboard toggle`, screenshot the
   calendar card. This refactor is the only part of the change that can break something
   that already works. Everything must match the pre-change shot except today's marker,
   which becomes a 26px circle instead of a wide stadium pill.
6. **Nav** — ydotool-click `‹`, `›` and the month label. Per prior session notes the
   scroll wheel cannot be simulated, so **wheel-to-change-month needs manual testing by
   the user**.
7. **stderr** — watch for `possible QQuickItem::polish() loop` naming either new file.
