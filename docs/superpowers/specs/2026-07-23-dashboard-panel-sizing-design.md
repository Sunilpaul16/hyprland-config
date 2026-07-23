# Dashboard panel configurable sizing

## Problem

The `SUPER+D` dashboard overlay (`DashboardPanel.qml`) currently has no user-configurable
size. Width is a fixed `85% of screen, capped at 1400px`. Height is content-driven —
the panel measures the active tab's natural content height and sizes itself to match
(built last session specifically to remove dead space below shorter tabs). Neither
dimension can be overridden by the user.

## Goal

Let the user set an explicit panel width and/or height in `config.json`. When set, the
panel should render at that size, and the cards/content inside every tab (Dashboard,
Media, Performance, Weather) should reflow to fit it — without per-tab redesign.

## Design

### Config.qml additions

Four new properties, following this repo's convention for fixed-value-set string
properties (trailing `// "a" | "b"` comment):

```qml
property alias dashboardPanelWidthMode: adapter.dashboardPanelWidthMode   // "auto" | "fixed"
property alias dashboardPanelWidth: adapter.dashboardPanelWidth
property alias dashboardPanelHeightMode: adapter.dashboardPanelHeightMode // "auto" | "fixed"
property alias dashboardPanelHeight: adapter.dashboardPanelHeight
```

JsonAdapter defaults: `dashboardPanelWidthMode: "auto"`, `dashboardPanelWidth: 1190`,
`dashboardPanelHeightMode: "auto"`, `dashboardPanelHeight: 700` (seed values only
used once someone flips a mode to `"fixed"`). Width and height modes are independent —
either can be fixed while the other stays auto.

### DashboardPanel.qml — panel sizing

```qml
readonly property bool widthFixed: Config.dashboardPanelWidthMode === "fixed"
readonly property bool heightFixed: Config.dashboardPanelHeightMode === "fixed"

// Panel Rectangle
width: root.widthFixed
    ? Math.min(Config.dashboardPanelWidth, (root.screen?.width ?? 1280) * 0.95)
    : Math.min((root.screen?.width ?? 1280) * 0.85, 1400)

height: root.heightFixed
    ? Math.min(Config.dashboardPanelHeight, (root.screen?.height ?? 800) * 0.95)
    : Math.min(contentColumn.implicitHeight + 40, (root.screen?.height ?? 800) * 0.85, 900)

clip: true   // new — silently clips content that can't shrink to fit a fixed size
```

The `* 0.95` screen clamp is a safety ceiling that only applies in fixed mode (so a
config typo like `9999` can't push the panel off-monitor). Auto mode keeps its existing
`0.85` / `1400` / `900` caps unchanged — byte-for-byte the same behavior as today.

### Height propagation (the real behavioral change)

Width already flows top-down today: each tab's `Loader` has an explicit `width` bound
to the panel's available width, and Qt's default Loader→item size binding applies that
to the tab's root `Item` with no extra wiring. Every card already reflows via existing
`Layout.fillWidth`/`preferredWidth` bindings. So a fixed panel width needs no per-tab
changes — it falls out of bindings that already exist.

Height is the opposite today: it flows bottom-up (content height → panel height), which
is exactly what last session's dead-space fix relies on. Making height configurable
requires flipping the direction when fixed mode is active:

```qml
// tabView (Flickable)
Layout.fillHeight: root.heightFixed
Layout.preferredHeight: root.heightFixed ? -1 : currentPaneHeight

// paneLoader (inside paneRow's Repeater)
height: root.heightFixed ? tabView.height : (item ? item.implicitHeight : 0)
```

In fixed mode, `tabView.height` becomes panel-driven; each tab's Loader hands that down
to the tab's root `Item` (same Loader→item size-binding mechanism relied on for width);
every card that already has `Layout.fillHeight: true` (Calendar, Resources, Media,
DateTime cards) reflows into whatever room remains. Cards without `fillHeight` (e.g.
`SmallWeatherCard`'s fixed 200px row) don't shrink — at a configured height too short to
fit everything, those bits are cropped by the panel's new `clip: true` rather than the
panel growing past the configured size or content overlapping/breaking visually.

Auto mode (the default for both dimensions) is unchanged from today's behavior.

### Explicitly out of scope

- Responsive column-count changes (e.g. Dashboard/Performance grids dropping from 2
  columns to 1 at small widths) — column count stays fixed; only card widths reflow.
- Scrollable overflow — overflow is clipped, not scrollable.
- Per-card size configs (`Config.dashboardUserWidth` etc., added last session) are
  unaffected — they remain the GridLayout's preferred/stretch basis, same as today.

## Verification plan

No test suite in this repo — verified live per `CLAUDE.md` convention:

1. `qmllint` the touched files (`Config.qml`, `DashboardPanel.qml`) — the known
   exit-255/no-output quirk on `Config.qml`'s bare same-directory singleton reference is
   expected and not a real error.
2. Restart `qs` (`pkill -x qs; qs -n -c shell`), confirm clean `Configuration Loaded`
   with no `ERROR:` in output.
3. Set `dashboardPanelWidthMode`/`HeightMode` to `"fixed"` with a few different pixel
   values (small, large, ~default) in `~/.config/quickshell/config.json`, reopen the
   dashboard via `qs -c shell ipc call dashboard open`, and screenshot each of the 4 tabs
   to confirm reflow and clipping behave as designed.
4. Confirm `"auto"` mode still renders identically to today's behavior (regression
   check against the current, already-committed layout).
