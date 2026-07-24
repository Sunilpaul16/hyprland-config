# Tray Inline Overflow Expand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cap the bar's tray pill at 3 inline icons; a 4th+ background app collapses behind a `chevron_left` arrow that expands the tray inline (no popup) via a slide animation.

**Architecture:** `Tray.qml`'s existing `visibleItems` list (already `nm-applet`/`blueman`-filtered) is sliced into `alwaysVisibleItems` (first 3) and `overflowItems` (the rest). A new `expanded` bool picks which slice the `Repeater` renders. Because `Tray`'s `SectionPill` sits before the Clock pill inside `Bar.qml`'s right-anchored `rightRow`, animating `Tray`'s own `implicitWidth` (via `Behavior` + `clip: true`) naturally slides growth to the left without any manual positioning logic — Clock/session button don't move.

**Tech Stack:** QML / Quickshell (`Item`, `Row`, `Repeater`, `MaterialIcon`, `Motion` singleton).

**Full design reference:** `docs/superpowers/specs/2026-07-24-tray-overflow-expand-design.md`

## Global Constraints

- No test suite in this repo — verify live per `CLAUDE.md`: `qmllint` the touched file, restart `qs` (`pkill -x qs; qs -n -c shell`), confirm clean `Configuration Loaded` with no `ERROR:` line, then exercise the real UI and screenshot.
- No persisted state for `expanded` (unlike the reverted `#35` `hiddenTrayIds`) — plain transient QML property.
- Reuse existing conventions exactly: `chevron_left`/`chevron_right` icon names (already used in `QuickTogglesRow.qml`), `Motion.deliberateDuration`/`Motion.deliberateEasing` for the width `Behavior` (this repo's token for "layout/resize/reflow"), and the old `overflowBtn`'s 18×18/`MaterialIcon`/hover-color/`MouseArea -4margin` shape (from the now-reverted commit `5c49b83`, still visible via `git show 5c49b83`) for the new arrow's look.
- Live test rig already running: 5 dummy `StatusNotifierItem` tray apps (Discord/Steam/Slack/Spotify/Telegram stand-ins, PIDs 162582–162586, script at `/home/spaul16/.claude/jobs/674b4b41/tmp/dummy_tray.py`) plus your real Chrome tray icon are currently registered with `qs`'s `StatusNotifierWatcher` — gives 6 visible tray items post-filter, well over the 3-icon cap, so no extra setup is needed to see the overflow arrow and expand animation live. If `qs` gets restarted between now and testing, re-verify they're still registered with:
  ```
  busctl --user call org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.freedesktop.DBus.Properties Get ss org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
  ```
  If any dummy PID is missing from that list (a prior run hit the documented D-Bus name-ownership race), re-register it manually:
  ```
  busctl --user call org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisterStatusNotifierItem s "org.kde.StatusNotifierItem-<pid>-<rand>"
  ```
  (bus name printed by the script's own stdout log at `/home/spaul16/.claude/jobs/674b4b41/tmp/<app-id>.log` when it started).
- Only the final step commits — this is one cohesive single-file feature, matching this repo's one-commit-per-logical-change convention.

---

### Task 1: `Tray.qml` — overflow split, expand toggle, slide animation

**Files:**
- Modify: `quickshell/shell/modules/bar/Tray.qml`

**Interfaces:**
- Produces: nothing consumed elsewhere — `Bar.qml`'s existing `tray.hasItems` binding (`Bar.qml:146`) is untouched and keeps working unchanged, since `hasItems` still reflects `visibleItems.length > 0` regardless of collapse/expand state.

- [ ] **Step 1: Read the current file to confirm line numbers before editing**

Run: `cat -n quickshell/shell/modules/bar/Tray.qml`
(The file was reverted to its pre-`5c49b83` shape earlier this session — confirm it still matches what's quoted below before editing; if it doesn't, stop and re-sync with the actual file contents instead of applying the diff blind.)

- [ ] **Step 2: Add overflow-split and expand-state properties**

Find:

```qml
    readonly property var visibleItems: SystemTray.items.values.filter(item => !root.isHidden(item))
    readonly property bool hasItems: root.visibleItems.length > 0
```

Replace with:

```qml
    readonly property var visibleItems: SystemTray.items.values.filter(item => !root.isHidden(item))
    readonly property bool hasItems: root.visibleItems.length > 0

    readonly property int maxVisible: 3
    readonly property var alwaysVisibleItems: root.visibleItems.slice(0, root.maxVisible)
    readonly property var overflowItems: root.visibleItems.slice(root.maxVisible)
    readonly property bool hasOverflow: root.overflowItems.length > 0
    readonly property var displayedItems: root.expanded ? root.visibleItems : root.alwaysVisibleItems

    property bool expanded: false

    // Start collapsed again next time there's something to hide, rather
    // than resuming pre-expanded once overflow reappears
    onHasOverflowChanged: if (!root.hasOverflow) root.expanded = false
```

- [ ] **Step 3: Animate the root item's width and clip it**

Find:

```qml
    visible: root.hasItems
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight
```

Replace with:

```qml
    visible: root.hasItems
    clip: true
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }
```

- [ ] **Step 4: Add the `Motion`/`Colors` imports needed by the new arrow**

Find the top of the file:

```qml
import QtQuick
import Quickshell.Services.SystemTray

// System tray: row of TrayItem icons, reactive to SystemTray.items
Item {
    id: root
```

Replace with:

```qml
import QtQuick
import Quickshell.Services.SystemTray
import "../../services"

// System tray: row of TrayItem icons, reactive to SystemTray.items
Item {
    id: root
```

- [ ] **Step 5: Switch the Repeater's model and append the expand/collapse arrow**

Find:

```qml
        Repeater {
            model: root.visibleItems

            TrayItem {
                required property SystemTrayItem modelData
                item: modelData
            }
        }
    }
}
```

Replace with:

```qml
        Repeater {
            model: root.displayedItems

            TrayItem {
                required property SystemTrayItem modelData
                item: modelData
            }
        }

        // Overflow expand/collapse toggle — only shown once something's
        // actually hidden past maxVisible
        Item {
            id: overflowBtn
            visible: root.hasOverflow
            implicitWidth: 18
            implicitHeight: 18

            MaterialIcon {
                anchors.centerIn: parent
                text: root.expanded ? "chevron_right" : "chevron_left"
                color: overflowHover.containsMouse ? Colors.text : Colors.textMuted
                font.pixelSize: 16
            }

            MouseArea {
                id: overflowHover
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }
    }
}
```

- [ ] **Step 6: Lint**

Run: `qmllint quickshell/shell/modules/bar/Tray.qml`
Expected: exit 0, no output. (`Tray.qml` has no native Quickshell types and no bare same-directory singleton reference — the `"../../services"` import added in Step 4 is a normal relative import, same pattern `Bar.qml` already uses for `Colors`/`Config`, so this file is not expected to hit the documented qmllint quirk.)

- [ ] **Step 7: Restart `qs` and confirm clean load**

Run: `pkill -x qs; qs -n -c shell`
Expected: stdout shows `Configuration Loaded` with no `ERROR:` line.

- [ ] **Step 8: Verify collapsed state (3 icons + arrow) live**

Confirm the dummy tray apps from the Global Constraints section are still registered (re-run the `busctl ... RegisteredStatusNotifierItems` check; re-register any missing ones as described there).

Run: `hyprctl monitors -j | jq '.[] | {name, focused}'` to find the focused monitor, then `grim -o <focused-monitor> /home/spaul16/.claude/jobs/674b4b41/tmp/tray-collapsed.png`.
Expected: exactly 3 tray icons visible inline in the bar's tray pill, followed by a left-pointing chevron arrow. No popup, no "..." icon.

- [ ] **Step 9: Verify expand animation and full icon reveal live**

Since click simulation isn't available in this sandbox, temporarily change `property bool expanded: false` to `property bool expanded: true` in `Tray.qml` (Quickshell hot-reloads on save — no restart needed), then re-screenshot: `grim -o <focused-monitor> /home/spaul16/.claude/jobs/674b4b41/tmp/tray-expanded.png`.
Expected: all 6 tray icons now visible inline (5 dummies + Chrome), arrow now points right (`chevron_right`), tray pill visibly wider, Clock and the session/power button to its right have NOT moved position between the collapsed and expanded screenshots (compare pixel position against `tray-collapsed.png`), no clipped/cut-off icons, no QML errors in the `qs` log.

- [ ] **Step 10: Revert the temporary test edit**

Change `property bool expanded: true` back to `property bool expanded: false` in `Tray.qml`.

- [ ] **Step 11: Commit**

```bash
git add quickshell/shell/modules/bar/Tray.qml
git commit -m "$(cat <<'EOF'
tray: inline overflow expand past 3 icons

Caps the tray pill at 3 inline icons; a 4th+ background app collapses
behind a chevron_left arrow instead of growing the pill unbounded.
Clicking it expands inline via a width Behavior + clip (no popup,
unlike the reverted #35 attempt) -- Tray's SectionPill sits before
Clock in Bar.qml's right-anchored rightRow, so the growth naturally
slides left without needing any manual positioning logic.
EOF
)"
```

- [ ] **Step 12: Verify commit**

Run: `git status`
Expected: `nothing to commit, working tree clean` (aside from any pre-existing unrelated changes already in the working tree before this task started), branch ahead of `origin/main` by one more commit than before this feature.

---

### Task 2: Clean up the dummy tray test rig

**Files:**
- No file edits — process/D-Bus cleanup only.

**Interfaces:**
- Consumes: the 5 dummy `StatusNotifierItem` processes started during brainstorming (PIDs 162582–162586).

- [ ] **Step 1: Kill the dummy tray processes**

Run: `kill 162582 162583 162584 162585 162586 2>/dev/null; pkill -f dummy_tray.py`
Expected: no output (processes may already be gone if the session/PIDs recycled — that's fine, not an error).

- [ ] **Step 2: Confirm they're gone from the watcher**

Run: `busctl --user call org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.freedesktop.DBus.Properties Get ss org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems`
Expected: only real items remain (Chrome/nm-applet/blueman-style entries), no `org.kde.StatusNotifierItem-<pid>-<rand>` dummy entries.

- [ ] **Step 3: Final live screenshot with real tray state**

Run: `pkill -x qs; qs -n -c shell`, confirm clean `Configuration Loaded`, then screenshot the focused monitor's bar again to confirm the tray now renders normally with real background apps only (likely back under the 3-icon cap, arrow hidden).
