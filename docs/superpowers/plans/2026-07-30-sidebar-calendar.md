# Sidebar Calendar Card Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a collapsible month-calendar card to the bottom of the right sidebar, below notifications, by extracting the dashboard's existing inline month grid into a shared component used by both.

**Architecture:** One new `components/CalendarGrid.qml` owns all month-grid logic and draws no card chrome. Two thin callers wrap it in their own surface: the dashboard's existing `CalendarCard` (26px cells, circular day pills, "Today" button) and a new `modules/sidebarRight/CalendarCard.qml` (~39px cells filling the column, rounded-square pills, a collapse chevron instead of the Today button). Collapse state lives in `Config.sidebar.calendarCollapsed`.

**Tech Stack:** QML (Qt 6), Quickshell. Qt Quick Controls' `MonthGrid` / `DayOfWeekRow` back the grid. No new services, no new dependencies.

**Spec:** `docs/superpowers/specs/2026-07-30-sidebar-calendar-design.md`

## Global Constraints

- **This repo has no test suite, no CI and no build step.** Verification means: lint the touched QML, restart the shell, and exercise it live. A code read is never evidence.
- **Lint with Qt 6's qmllint, not `/usr/bin/qmllint`** (that one is Qt 5's and parses almost nothing). Exact command in every lint step below.
- **`Type QProcess::ExitStatus ... was not found` on `Process.onExited` is a known false positive.** Ignore it. Everything else qmllint reports here is real.
- **A clean lint does not prove signal wiring.** A handler bound to a non-existent signal only fails at load. Counting `Configuration Loaded` in the restart output is the real evidence.
- **Editing files in this repo edits the live config.** `quickshell/` is symlinked into `~/.config/quickshell`. There is no deploy step.
- **Overlay panels only render on the Hyprland-focused monitor.** Run `hyprctl monitors -j | jq -r '.[] | "\(.name) focused=\(.focused)"'` before every screenshot; a blank capture usually means you shot the wrong output. On this machine DP-2 and DP-3 are both 2560x1440.
- **Comment style:** terse block-label signposts only (`// Viewed month`, `// Weekday header row`) — a few words naming *what a block is*, never explaining how it works. Do not caption a block whose own identifier already says what it is. One line maximum. Existing trap-notes/why-comments must not be moved or reworded.
- **Rounding must use a `Motion.rounding` step**, never a raw literal. A circle is `radius: width / 2`, never the number that happens to equal it.
- **Cards use `Colors.layer`; panel backgrounds use `Colors.panel`.** Do not swap these.
- **Commit after each task.** One commit per task, `shell:` prefix, matching this repo's history.

---

### Task 1: Extract `CalendarGrid` and refactor the dashboard onto it

Pure refactor plus one bug fix. The dashboard must look identical afterwards **except** that its weekday headers become aligned with their columns.

**Files:**
- Create: `quickshell/shell/components/CalendarGrid.qml`
- Modify: `quickshell/shell/modules/dashboard/DashTab.qml:137-333` (the `CalendarCard` and `NavButton` components, replaced wholesale)
- Verify by screenshot: the dashboard's Dashboard tab

**Interfaces:**
- Produces: `CalendarGrid`, an `Item` with properties `cellSize: int` (default 26), `cellSpacing: int` (default 4), `dayRadius: int` (default `Motion.rounding.small`), `showTodayButton: bool` (default true), `headerLeftInset: int` (default 0), `viewDate: date`; functions `goToToday()` and `stepMonth(delta: int)`; and a content-derived `implicitWidth` / `implicitHeight`. Task 2 and Task 3 consume all of these.
- Consumes: nothing from earlier tasks.

- [ ] **Step 1: Capture the current dashboard calendar as a "before" reference**

The alignment bug this task fixes is a claim from reading Qt's sources. Prove it on screen first, so the after-shot has something to be compared against.

```bash
hyprctl monitors -j | jq -r '.[] | "\(.name) focused=\(.focused)"'
qs -c shell ipc call dashboard toggle
sleep 1
grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" \
  /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/cal-before.png
qs -c shell ipc call dashboard toggle
```

Open `cal-before.png` and look at the calendar card. Expected: the `M T W T F S S` header letters do **not** line up over the day-number columns — the headers are on a different pitch (natural text width, `spacing: 6`) than the cells (fixed 26px, `spacing: 4`).

**If they turn out to be aligned,** the premise is wrong: stop and report it rather than "fixing" a non-bug. The extraction is still worth doing, but drop the alignment claim from the commit message.

- [ ] **Step 2: Create `components/CalendarGrid.qml`**

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services"

// Month calendar grid — draws no card chrome; the caller owns its surface
Item {
    id: root

    // MonthGrid and DayOfWeekRow are plain positioners that never resize their
    // delegates, so both rows must be driven from one size to stay on the same pitch
    property int cellSize: 26
    property int cellSpacing: 4
    property int dayRadius: Motion.rounding.small
    property bool showTodayButton: true
    // Space reserved at the head of the nav row for a caller's own button
    property int headerLeftInset: 0

    // Viewed month
    property date viewDate: new Date()
    readonly property int viewMonth: viewDate.getMonth()
    readonly property int viewYear: viewDate.getFullYear()
    readonly property bool onCurrentMonth: {
        const now = new Date();
        return viewMonth === now.getMonth() && viewYear === now.getFullYear();
    }

    // Changes only at midnight; binding delegates to Time.date would re-evaluate all 42 every second
    readonly property string todayKey: Time.format("yyyy-MM-dd")

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    function goToToday(): void {
        root.viewDate = new Date();
    }

    function stepMonth(delta: int): void {
        root.viewDate = new Date(root.viewYear, root.viewMonth + delta, 1);
    }

    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.stepMonth(-1);
            else if (event.angleDelta.y < 0)
                root.stepMonth(1);
        }
    }

    // Middle-click jumps back to today
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: root.goToToday()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: 8

        // Month navigation + jump-to-today
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Item {
                visible: root.headerLeftInset > 0
                Layout.preferredWidth: root.headerLeftInset
                Layout.preferredHeight: 1
            }

            NavButton {
                glyph: "‹"
                onClicked: root.stepMonth(-1)
            }

            // Clicking the month label also jumps to today (caelestia's affordance)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: monthLabel.implicitHeight + 8
                radius: height / 2
                color: monthArea.containsMouse && !root.onCurrentMonth ? Colors.outline : "transparent"

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                Text {
                    id: monthLabel

                    anchors.centerIn: parent
                    text: root.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Colors.primary
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: monthArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.onCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: root.goToToday()
                }
            }

            NavButton {
                glyph: "›"
                onClicked: root.stepMonth(1)
            }

            Rectangle {
                visible: root.showTodayButton
                implicitWidth: todayLabel.implicitWidth + 16
                implicitHeight: 24
                radius: Motion.rounding.normal
                color: root.onCurrentMonth ? "transparent" : Colors.primary
                border.width: root.onCurrentMonth ? 1 : 0
                border.color: Colors.outline

                Text {
                    id: todayLabel

                    anchors.centerIn: parent
                    text: "Today"
                    color: root.onCurrentMonth ? Colors.textMuted : Colors.background
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToToday()
                }
            }
        }

        // Weekday header row — same cell width and spacing as the grid below,
        // which is what keeps the two on the same pitch
        DayOfWeekRow {
            id: dayRow

            Layout.alignment: Qt.AlignHCenter
            locale: grid.locale
            spacing: root.cellSpacing

            delegate: Text {
                required property var model

                // Qt::DayOfWeek: Monday=1 .. Sunday=7
                readonly property bool isWeekend: model.day === 6 || model.day === 7

                width: root.cellSize
                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                color: isWeekend ? Colors.primary : Colors.textMuted
                font.pixelSize: 11
            }
        }

        MonthGrid {
            id: grid

            Layout.alignment: Qt.AlignHCenter
            month: root.viewMonth
            year: root.viewYear
            locale: Qt.locale()
            spacing: root.cellSpacing

            delegate: Rectangle {
                id: dayCell

                required property var model

                // JS Date.getDay(): Sunday=0 .. Saturday=6
                readonly property bool isWeekend: {
                    const d = dayCell.model.date.getDay();
                    return d === 0 || d === 6;
                }
                readonly property bool isToday: Qt.formatDate(dayCell.model.date, "yyyy-MM-dd") === root.todayKey

                implicitWidth: root.cellSize
                implicitHeight: root.cellSize
                radius: root.dayRadius
                color: isToday ? Colors.primary : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: dayCell.model.day
                    font.pixelSize: 12
                    color: dayCell.isToday ? Colors.background : (dayCell.isWeekend ? Colors.primary : Colors.text)
                    opacity: dayCell.model.month === grid.month ? 1 : 0.35
                }
            }
        }
    }

    component NavButton: Rectangle {
        id: navBtn

        required property string glyph
        signal clicked

        implicitWidth: 26
        implicitHeight: 26
        radius: width / 2
        color: navArea.containsMouse ? Colors.outline : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Text {
            anchors.centerIn: parent
            text: navBtn.glyph
            color: Colors.text
            font.pixelSize: 15
        }

        MouseArea {
            id: navArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navBtn.clicked()
        }
    }
}
```

Two deliberate differences from the code being replaced, both from the spec:

1. `isToday` compares against `root.todayKey` instead of using `model.today`. `model.today` is computed by the calendar model and will not re-evaluate while the component stays alive, so the highlight would stick to the wrong day past midnight.
2. `DayOfWeekRow` and `MonthGrid` now share `root.cellSpacing`, and the weekday delegate has an explicit `width: root.cellSize`. This is the alignment fix.

- [ ] **Step 3: Replace the dashboard's inline calendar with the shared grid**

In `quickshell/shell/modules/dashboard/DashTab.qml`, delete everything from `// Full month grid: prev/next navigation, jump-to-today, current-day highlight` (line 137) through the closing brace of `component NavButton` (line 333) and put this in its place:

```qml
    // Full month grid: prev/next navigation, jump-to-today, current-day highlight
    component CalendarCard: Rectangle {
        radius: Motion.rounding.large
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline
        implicitHeight: cal.implicitHeight + 32

        CalendarGrid {
            id: cal

            anchors.fill: parent
            anchors.margins: 16
            cellSize: 26
            // Circular day pills, the look this card already had
            dayRadius: cellSize / 2
        }
    }
```

Then fix the imports at the top of the file:

- **Add** `import "../../components"` (for `CalendarGrid`).
- **Remove** `import QtQuick.Controls` — `MonthGrid` and `DayOfWeekRow` were its only users in this file, and they have moved. Step 4's lint will flag it as unused if you forget, and will error if something else did need it.

`NavButton` was used only by the calendar header (lines 184 and 218), so it moves into `CalendarGrid` with no other caller left behind. Confirm before deleting:

```bash
grep -n "NavButton" quickshell/shell/modules/dashboard/DashTab.qml
```

Expected after the edit: no matches.

- [ ] **Step 4: Lint both files**

```bash
cd /home/spaul16/hyprland-config
/usr/lib/qt6/bin/qmllint -I quickshell/shell -I /usr/lib/qt6/qml \
  --missing-property disable --import disable --unqualified disable \
  --unresolved-type disable --missing-type disable --incompatible-type disable \
  --uncreatable-type disable \
  quickshell/shell/components/CalendarGrid.qml \
  quickshell/shell/modules/dashboard/DashTab.qml
```

Expected: exit 0, no warnings. An "unused import" warning means Step 3's import cleanup was wrong.

- [ ] **Step 5: Restart the shell and confirm it actually loaded**

```bash
pkill -x qs; qs -n -c shell 2>&1 | tee /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task1.log &
sleep 3
grep -c "Configuration Loaded" /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task1.log
```

Expected: `1` or more. If you see `ERROR: Failed to load configuration`, read the error's import chain top-down — the first entry names the file with the actual syntax error.

Also check for layout loops, which name their own file and line:

```bash
grep -i "polish() loop" /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task1.log
```

Expected: no matches.

- [ ] **Step 6: Screenshot the dashboard and compare against the before-shot**

```bash
qs -c shell ipc call dashboard toggle
sleep 1
grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" \
  /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/cal-after.png
qs -c shell ipc call dashboard toggle
```

Open both images side by side. The calendar card must be **unchanged** in: position, size, border, circular day pills, today's filled pill, weekend tinting, dimmed out-of-month days, and the "Today" button. The **only** difference should be the `M T W T F S S` headers now sitting over their columns.

Any other visual difference is a regression in the extraction — fix it before committing.

- [ ] **Step 7: Commit**

```bash
git add quickshell/shell/components/CalendarGrid.qml quickshell/shell/modules/dashboard/DashTab.qml
git commit -m "shell: extract the month grid into a shared CalendarGrid component

Aligns the weekday headers with their columns as a side effect: MonthGrid
and DayOfWeekRow are plain positioners that never resize delegates, so the
two rows were laid out on different pitches."
```

---

### Task 2: Add the calendar card to the sidebar (expanded only)

No collapse yet — that is Task 3. This task's deliverable is a working, correctly-sized calendar at the bottom of the sidebar.

**Files:**
- Create: `quickshell/shell/modules/sidebarRight/CalendarCard.qml`
- Modify: `quickshell/shell/modules/sidebarRight/SidebarRightPanel.qml:155-159` (append after `NotificationsCard`)

**Interfaces:**
- Consumes: `CalendarGrid` from Task 1 — `cellSize`, `cellSpacing`, `showTodayButton`, `goToToday()`, `implicitHeight`.
- Produces: `CalendarCard`, a `Rectangle` with a content-derived `implicitHeight`. Task 3 adds a `collapsed` property to it.

- [ ] **Step 1: Create `modules/sidebarRight/CalendarCard.qml`**

```qml
import QtQuick
import "../../services"
import "../../components"

// Calendar card pinned to the bottom of the sidebar column
Rectangle {
    id: root

    radius: Motion.rounding.large
    color: Colors.layer
    clip: true

    implicitHeight: grid.implicitHeight + 32

    CalendarGrid {
        id: grid

        anchors.fill: parent
        anchors.margins: 16
        showTodayButton: false
        cellSpacing: 5
        // Seven cells and six gaps across the card's content width
        cellSize: Math.floor((root.width - 32 - cellSpacing * 6) / 7)
    }

    // The sidebar's LazyLoader keeps this alive between opens, so a month
    // navigated to earlier would otherwise still be showing on the next open
    Connections {
        target: SidebarRightState

        function onOpenChanged() {
            if (SidebarRightState.open)
                grid.goToToday();
        }
    }
}
```

The `cellSize` binding cannot cause a `QQuickItem::polish()` loop: width flows *down* from the sidebar backdrop's fixed 360px, height flows *up* from the grid's content. Different axes.

- [ ] **Step 2: Wire it into the sidebar column**

In `quickshell/shell/modules/sidebarRight/SidebarRightPanel.qml`, directly after the existing `NotificationsCard { ... }` block (currently ending at line 159) and still inside the `ColumnLayout`:

```qml
                        CalendarCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: implicitHeight
                        }
```

Do **not** add a divider. The existing one above `NotificationsCard` marks the utility-cards boundary; the 12px column spacing and the card's own `Colors.layer` fill separate this well enough.

Leave `NotificationsCard`'s `Layout.fillHeight: true` and `Layout.minimumHeight: 120` exactly as they are — that is what makes notifications absorb the remaining height.

- [ ] **Step 3: Lint**

```bash
cd /home/spaul16/hyprland-config
/usr/lib/qt6/bin/qmllint -I quickshell/shell -I /usr/lib/qt6/qml \
  --missing-property disable --import disable --unqualified disable \
  --unresolved-type disable --missing-type disable --incompatible-type disable \
  --uncreatable-type disable \
  quickshell/shell/modules/sidebarRight/CalendarCard.qml \
  quickshell/shell/modules/sidebarRight/SidebarRightPanel.qml
```

Expected: exit 0.

- [ ] **Step 4: Restart and confirm the load**

```bash
pkill -x qs; qs -n -c shell 2>&1 | tee /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task2.log &
sleep 3
grep -c "Configuration Loaded" /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task2.log
grep -i "polish() loop\|Cannot assign to non-existent" /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task2.log
```

Expected: count `1` or more, and no matches on the second grep. `Cannot assign to non-existent property` here would mean the `Connections` handler name is wrong — `SidebarRightState.open` is a `property bool`, so `onOpenChanged` is the correct handler.

- [ ] **Step 5: Screenshot the sidebar and check the geometry**

```bash
hyprctl monitors -j | jq -r '.[] | "\(.name) focused=\(.focused)"'
qs -c shell ipc call sidebarRight open
sleep 1
grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" \
  /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/sidebar-cal.png
qs -c shell ipc call sidebarRight close
```

Check in the image:

- The calendar sits at the bottom of the sidebar, below notifications, in the area the empty-state watermark used to have to itself.
- **All six week rows are visible.** `clip: true` will silently cut the last row if the height maths is wrong — this is the specific failure to look for.
- Weekday headers sit over their columns.
- Day cells are noticeably larger than the dashboard's (~39px vs 26px) and the grid spans the card's width rather than hugging the left edge.
- Today is a filled rounded square (not a circle — that is intentional here, matching end-4).
- No "Today" button in the header.
- Notifications still fills the space above and its dino watermark is still centred in what is left.

- [ ] **Step 6: Verify the reset-on-open behaviour**

Needs a real click, since the nav buttons have no IPC surface:

```bash
qs -c shell ipc call sidebarRight open
```

Click `›` three times to move the view forward three months, then close the sidebar (Escape or `qs -c shell ipc call sidebarRight close`), then reopen it. Expected: the header shows the **current** month again, not the one you navigated to.

- [ ] **Step 7: Commit**

```bash
git add quickshell/shell/modules/sidebarRight/CalendarCard.qml \
        quickshell/shell/modules/sidebarRight/SidebarRightPanel.qml
git commit -m "shell: add a calendar card below the sidebar's notification list"
```

---

### Task 3: Collapse to a one-line date row

**Files:**
- Modify: `quickshell/shell/services/Config.qml:72-74` (the `sidebar` group)
- Modify: `quickshell/shell/modules/sidebarRight/CalendarCard.qml` (from Task 2)
- Modify: `~/.config/quickshell/config.json` — **live file, migrated by hand, see Step 2**

**Interfaces:**
- Consumes: `CalendarCard` from Task 2, `CalendarGrid.headerLeftInset` from Task 1.
- Produces: `Config.sidebar.calendarCollapsed: bool`.

- [ ] **Step 1: Add the config key**

In `quickshell/shell/services/Config.qml`, the `sidebar` group currently holds one property. Add a second:

```qml
            property JsonObject sidebar: JsonObject {
                property string noNotifsImage: "" // notifications empty-state watermark; "" = the bundled assets/dino.png
                property bool calendarCollapsed: false // sidebar calendar card starts collapsed
            }
```

**No `property alias` is needed** — `sidebar` is an existing group and already has one at the top of the file. Only brand-new *groups* need an alias, and forgetting it there yields a silent runtime `TypeError`, not a load error.

- [ ] **Step 2: Confirm the live config file picks the key up**

`~/.config/quickshell/config.json` lives outside this repo (deliberately — the shell hot-reloads on any change under `quickshell/shell/`, so a live-written file in there would reset the shell on every setting change). A new key with a default is additive and `JsonAdapter` will write it on the next save, so no hand-migration is needed here. Verify rather than assume:

```bash
jq '.sidebar' ~/.config/quickshell/config.json
```

Expected before the restart in Step 5: `{"noNotifsImage": ""}` or similar, without `calendarCollapsed`. After that restart, re-run it and expect `calendarCollapsed: false` to have appeared. If it has not, the shell is not writing the adapter back — investigate before continuing, because Step 6's persistence check depends on it.

- [ ] **Step 3: Add the collapse UI to `CalendarCard.qml`**

Replace the whole file with:

```qml
import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Calendar card pinned to the bottom of the sidebar column
Rectangle {
    id: root

    readonly property bool collapsed: Config.sidebar.calendarCollapsed

    radius: Motion.rounding.large
    color: Colors.layer
    clip: true

    implicitHeight: root.collapsed ? collapsedRow.implicitHeight + 24 : grid.implicitHeight + 32

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
    }

    CalendarGrid {
        id: grid

        anchors.fill: parent
        anchors.margins: 16
        showTodayButton: false
        cellSpacing: 5
        // Seven cells and six gaps across the card's content width
        cellSize: Math.floor((root.width - 32 - cellSpacing * 6) / 7)
        // Room for the collapse chevron at the head of the nav row
        headerLeftInset: 30

        opacity: root.collapsed ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
        }
    }

    // Collapsed state: chevron and the date on one line
    RowLayout {
        id: collapsedRow

        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        opacity: root.collapsed ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
        }

        Item {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
        }

        Text {
            Layout.fillWidth: true
            text: Time.dateStr
            color: Colors.text
            font.pixelSize: 14
        }
    }

    // Collapse toggle — sits above both states so it stays clickable through the cross-fade
    Rectangle {
        id: chevron

        anchors { left: parent.left; top: parent.top; margins: 12 }
        implicitWidth: 26
        implicitHeight: 26
        radius: width / 2
        color: chevronArea.containsMouse ? Colors.outline : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.collapsed ? "keyboard_arrow_up" : "keyboard_arrow_down"
            color: Colors.text
            font.pixelSize: 18
        }

        MouseArea {
            id: chevronArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.sidebar.calendarCollapsed = !Config.sidebar.calendarCollapsed
        }
    }

    // The sidebar's LazyLoader keeps this alive between opens, so a month
    // navigated to earlier would otherwise still be showing on the next open
    Connections {
        target: SidebarRightState

        function onOpenChanged() {
            if (SidebarRightState.open)
                grid.goToToday();
        }
    }
}
```

Notes on three choices here, so they are not "simplified" away in review:

- The chevron is a **sibling of both states, not a child of either** — as a child it would fade out with the state it lives in and become unclickable mid-transition.
- `Time.dateStr` is already formatted `"ddd, MMM d"`, which gives `Thu, Jul 30`. Do not re-format it locally.
- `headerLeftInset: 30` reserves the chevron's 26px plus a little air, so the `‹` button does not sit underneath it.

- [ ] **Step 4: Lint**

```bash
cd /home/spaul16/hyprland-config
/usr/lib/qt6/bin/qmllint -I quickshell/shell -I /usr/lib/qt6/qml \
  --missing-property disable --import disable --unqualified disable \
  --unresolved-type disable --missing-type disable --incompatible-type disable \
  --uncreatable-type disable \
  quickshell/shell/modules/sidebarRight/CalendarCard.qml \
  quickshell/shell/services/Config.qml
```

Expected: exit 0.

- [ ] **Step 5: Restart and confirm the load**

```bash
pkill -x qs; qs -n -c shell 2>&1 | tee /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task3.log &
sleep 3
grep -c "Configuration Loaded" /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task3.log
grep -i "polish() loop\|TypeError\|Cannot assign" /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/qs-task3.log
jq '.sidebar' ~/.config/quickshell/config.json
```

Expected: count `1` or more, no matches on the second grep, and `calendarCollapsed: false` now present in the JSON (this is the Step 2 check completing).

- [ ] **Step 6: Exercise the collapse and prove it persists**

```bash
qs -c shell ipc call sidebarRight open
```

Click the chevron at the card's top-left. Expected: the card animates down to a single row reading the chevron plus today's date (`Thu, Jul 30`), the arrow flips to point up, and the notifications card grows to reclaim the space. Then:

```bash
jq '.sidebar.calendarCollapsed' ~/.config/quickshell/config.json
```

Expected: `true`.

```bash
pkill -x qs; qs -n -c shell &
sleep 3
qs -c shell ipc call sidebarRight open
```

Expected: the card is still collapsed. Click the chevron again to expand, confirm all six week rows return, and confirm the JSON goes back to `false`.

- [ ] **Step 7: Screenshot both states**

```bash
qs -c shell ipc call sidebarRight open
sleep 1
grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" \
  /tmp/claude-1001/-home-spaul16-hyprland-config/*/scratchpad/sidebar-cal-expanded.png
```

Collapse via the chevron, then capture again as `sidebar-cal-collapsed.png`. Both go in the completion report.

- [ ] **Step 8: Commit**

```bash
git add quickshell/shell/modules/sidebarRight/CalendarCard.qml quickshell/shell/services/Config.qml
git commit -m "shell: let the sidebar calendar collapse to a single date row"
```

---

## After the plan

- [ ] **Update `INDEX.md`** — add the sidebar calendar to the feature index and status board (it is the living status doc; gitignored, not published).
- [ ] **Ask the user to test wheel-to-change-month.** Scroll cannot be simulated in this environment (`ydotool` clicks work, the scroll wheel does not), so `WheelHandler` on both the sidebar and dashboard calendars is the one interaction that cannot be verified here. Do not report it as working.
- [ ] **`review/comparison.md` needs no edit** — this feature is not one of its numbered items.

## Deliberately out of scope

Recorded so a reviewer does not read these as omissions:

- **The nav rail and the To Do / Timer tabs** from end-4's `BottomWidgetGroup.qml`. Each needs its own service and storage; a rail with one button is clutter. Adding it later does not require redoing this work.
- **end-4's `calendar_layout.js`** (113 lines of hand-rolled month layout). Qt's `MonthGrid` already backs the dashboard card and gives the same result.
- **Short-screen overflow.** Below roughly 800px of height, notifications shrinks to its 120px floor and the column then overflows the backdrop. Both monitors here are 2560x1440, so it cannot occur on current hardware; no hiding threshold is being added for it.
