# Tray inline overflow expand

## Problem

`Tray.qml`'s system tray row shows every visible tray icon inline with no cap. With
more than a handful of background apps open, the pill can grow arbitrarily wide,
crowding the rest of the bar. A previous attempt at capping this (comparison.md #35,
commit `5c49b83`) used a "..." button opening a separate popup, which the user
disliked and had reverted.

## Goal

Cap the tray pill at 3 icons inline. When a 4th+ app registers a tray icon, replace
the would-be 4th icon slot with a `chevron_left` arrow. Clicking it expands the tray
inline (no popup) via a slide animation, revealing all hidden icons; clicking again
collapses back to 3.

## Design

### Tray.qml — overflow split + expand state

```qml
readonly property int maxVisible: 3
readonly property var alwaysVisibleItems: root.visibleItems.slice(0, root.maxVisible)
readonly property var overflowItems: root.visibleItems.slice(root.maxVisible)
readonly property bool hasOverflow: root.overflowItems.length > 0
readonly property var displayedItems: root.expanded ? root.visibleItems : root.alwaysVisibleItems

property bool expanded: false

// Reset to collapsed once there's nothing left to hide, so a later 4th
// app starts collapsed again rather than resuming pre-expanded
onHasOverflowChanged: if (!root.hasOverflow) root.expanded = false
```

`visibleItems` (the existing `nm-applet`/`blueman`-filtered list) is unchanged;
`alwaysVisibleItems`/`overflowItems` just slice it further.

### Row content

Repeater's model becomes `root.displayedItems` (was `root.visibleItems`). After the
Repeater, an arrow item — same 18×18/`MaterialIcon`/hover-color/`MouseArea -4margin`
shape the old `overflowBtn` used — sits as the last element in the row:

```qml
Item {
    visible: root.hasOverflow
    implicitWidth: 18
    implicitHeight: 18

    MaterialIcon {
        anchors.centerIn: parent
        text: root.expanded ? "chevron_right" : "chevron_left"
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 16
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
    }
}
```

### Slide animation — no manual direction logic needed

`Tray`'s root `Item` already binds `implicitWidth: row.implicitWidth`, and (via
default QML sizing) `width` tracks `implicitWidth` since nothing else constrains it.
Two additions make that a slide instead of a pop:

```qml
clip: true

Behavior on implicitWidth {
    NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
}
```

Because `Tray`'s `SectionPill` sits *before* the Clock pill inside `rightRow`
(right-anchored in `Bar.qml`), growing `Tray`'s width only pushes bar content to its
*left* — Clock/session button positions are unaffected by construction, not by any
extra logic here. This reproduces the "slide out right-to-left" effect the user asked
for using the anchor structure that already exists.

### Explicitly out of scope

- No persisted state (unlike the reverted `#35`'s `hiddenTrayIds`) — `expanded` is
  transient UI state, reset on shell restart like any other plain property.
- No secondary cap on expanded width — all overflow items show at once; this desktop
  realistically never has enough tray apps for that to matter (matches the answered
  brainstorming question).
- No change to `nm-applet`/`blueman` filtering or `hiddenIds` — orthogonal to this
  feature.

## Verification plan

No test suite in this repo — verified live per `CLAUDE.md` convention:

1. `qmllint quickshell/shell/modules/bar/Tray.qml` (expect clean exit 0; no native
   Quickshell types or bare same-directory singleton refs in this file, so the known
   quirk shouldn't apply here).
2. Restart `qs` (`pkill -x qs; qs -n -c shell`), confirm clean `Configuration Loaded`
   with no `ERROR:` in output.
3. Live-check with whatever real tray apps are currently running: confirm the arrow
   only appears once 4+ items are present, confirm collapsed view caps at 3, and
   (since click simulation isn't available in this sandbox) use `wtype`/manual click
   or a temporary `expanded: true` edit to verify the expanded layout, clipping, and
   that Clock/session button don't shift — screenshot via `grim` to confirm visually.
