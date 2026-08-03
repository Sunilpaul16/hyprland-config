import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../services"
import "../../components"

// Workspaces widget
Item {
    id: root
    property var screen

    readonly property var monitor: Hyprland.monitorFor(root.screen)

    readonly property var allWorkspaces: Hyprland.workspaces.values

    readonly property int minSlots: 4

    // Display slots
    readonly property var displaySlots: {
        const maxId = Math.max(root.minSlots, ...root.allWorkspaces.map(ws => ws.id), 0);
        const slots = [];
        for (let id = 1; id <= maxId; id++) {
            slots.push(root.allWorkspaces.find(ws => ws.id === id) ?? { id, active: false, isPlaceholder: true, monitor: null });
        }
        return slots;
    }

    readonly property int pillSize: 24
    readonly property int pillSpacing: 6
    readonly property real cell: pillSize + pillSpacing

    readonly property int activeIndex: displaySlots.findIndex(ws => !ws.isPlaceholder && ws.monitor === root.monitor && ws.active)

    // Workspace app classes
    function appWmClasses(ws) {
        if (!ws || ws.isPlaceholder)
            return [];
        const seen = new Set();
        const classes = [];
        for (const tl of ws.toplevels.values) {
            const wmClass = tl.lastIpcObject?.class ?? "";
            if (!wmClass || seen.has(wmClass))
                continue;
            seen.add(wmClass);
            classes.push(wmClass);
        }
        return classes;
    }


    readonly property int maxIconsPerSlot: 3
    readonly property int iconSize: Math.round(pillSize * 0.62)
    readonly property int iconGap: 2

    // Slot layout
    readonly property var slotLayout: {
        let x = 0;
        const layout = [];
        for (const ws of root.displaySlots) {
            const wmClasses = root.appWmClasses(ws);
            const shownIcons = wmClasses.slice(0, root.maxIconsPerSlot).map(c => AppIcons.resolve(c)).filter(i => i.length > 0);
            const extra = Math.max(0, wmClasses.length - root.maxIconsPerSlot);
            const occupied = !ws.isPlaceholder && ws.toplevels.values.length > 0;

            let width = root.pillSize;
            if (shownIcons.length > 0 || extra > 0) {
                const iconsWidth = shownIcons.length * root.iconSize + Math.max(0, shownIcons.length - 1) * root.iconGap;
                const extraWidth = extra > 0 ? root.iconSize : 0;
                const gapBeforeExtra = (extra > 0 && shownIcons.length > 0) ? root.iconGap : 0;
                width = Math.max(root.pillSize, iconsWidth + gapBeforeExtra + extraWidth + root.iconGap * 2);
            }

            layout.push({ ws, x, width, occupied, shownIcons, extra });
            x += width + root.pillSpacing;
        }
        return layout;
    }

    implicitWidth: slotLayout.length > 0 ? (slotLayout[slotLayout.length - 1].x + slotLayout[slotLayout.length - 1].width) : 0
    implicitHeight: pillSize

    // Occupied-slot backgrounds
    Repeater {
        model: root.slotLayout

        Rectangle {
            required property var modelData
            required property int index

            x: modelData.x
            width: modelData.width
            height: root.pillSize
            radius: height / 2
            color: Colors.layer
            opacity: (modelData.occupied && index !== root.activeIndex) ? 1 : 0

            Behavior on x { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
            Behavior on width { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
            Behavior on opacity { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
        }
    }

    // Active workspace highlight
    Rectangle {
        id: highlight
        visible: root.activeIndex >= 0
        radius: height / 2
        color: Colors.primary
        height: root.pillSize

        readonly property var activeSlot: root.activeIndex >= 0 ? root.slotLayout[root.activeIndex] : null

        x: activeSlot ? activeSlot.x : 0
        width: activeSlot ? activeSlot.width : root.pillSize

        Behavior on x { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
        Behavior on width { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
    }

    // Slot content
    Repeater {
        model: root.slotLayout

        Item {
            id: slot
            required property var modelData
            required property int index

            readonly property bool isActive: index === root.activeIndex
            readonly property bool hasIcons: modelData.shownIcons.length > 0 || modelData.extra > 0

            x: modelData.x
            width: modelData.width
            height: root.pillSize

            Behavior on x { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
            Behavior on width { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

            Row {
                visible: slot.hasIcons
                anchors.centerIn: parent
                spacing: root.iconGap

                Repeater {
                    model: slot.modelData.shownIcons

                    IconImage {
                        required property string modelData

                        asynchronous: true
                        source: Quickshell.iconPath(modelData, "")
                        implicitSize: root.iconSize
                    }
                }

                StyledText {
                    visible: slot.modelData.extra > 0
                    text: "+" + slot.modelData.extra
                    font.pixelSize: Motion.fontSize.tiny
                    font.bold: slot.isActive
                    color: slot.isActive ? Colors.textOnPrimary : Colors.textMuted
                }
            }

            StyledText {
                visible: !slot.hasIcons
                anchors.centerIn: parent
                text: modelData.ws.id
                font.pixelSize: Motion.fontSize.body
                font.bold: slot.isActive
                color: slot.isActive ? Colors.textOnPrimary : (modelData.occupied ? Colors.text : Colors.textMuted)

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
            }

            // Click switches
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${modelData.ws.id} })`)
            }
        }
    }
}
