import QtQuick
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

    // Workspace category glyphs
    function appGlyphs(ws) {
        if (!ws || ws.isPlaceholder)
            return [];
        const seen = new Set();
        const glyphs = [];
        for (const tl of ws.toplevels.values) {
            const wmClass = tl.lastIpcObject?.class ?? "";
            if (!wmClass)
                continue;
            const glyph = AppIcons.categoryFor(wmClass, "terminal");
            if (seen.has(glyph))
                continue;
            seen.add(glyph);
            glyphs.push(glyph);
        }
        return glyphs;
    }


    readonly property int maxIconsPerSlot: 3
    readonly property int iconSize: Math.round(pillSize * 0.66)
    readonly property int iconGap: Motion.spacing.small
    readonly property int iconPadding: Motion.spacing.small

    // Slot layout
    readonly property var slotLayout: {
        let x = 0;
        const layout = [];
        for (const ws of root.displaySlots) {
            const glyphs = root.appGlyphs(ws);
            const shownIcons = glyphs.slice(0, root.maxIconsPerSlot);
            const extra = Math.max(0, glyphs.length - root.maxIconsPerSlot);
            const occupied = !ws.isPlaceholder && ws.toplevels.values.length > 0;

            let width = root.pillSize;
            if (shownIcons.length > 0 || extra > 0) {
                const iconsWidth = shownIcons.length * root.iconSize + Math.max(0, shownIcons.length - 1) * root.iconGap;
                const extraWidth = extra > 0 ? root.iconSize : 0;
                const gapBeforeExtra = (extra > 0 && shownIcons.length > 0) ? root.iconGap : 0;
                width = Math.max(root.pillSize, iconsWidth + gapBeforeExtra + extraWidth + root.iconPadding * 2);
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
            color: Colors.pill
            opacity: (modelData.occupied && index !== root.activeIndex) ? 1 : 0

            Behavior on x { Anim {} }
            Behavior on width { Anim {} }
            Behavior on opacity { Anim {} }
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

        Behavior on x { Anim {} }
        Behavior on width { Anim {} }
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

            Behavior on x { Anim {} }
            Behavior on width { Anim {} }

            Row {
                visible: slot.hasIcons
                anchors.centerIn: parent
                spacing: root.iconGap

                Repeater {
                    model: slot.modelData.shownIcons

                    Item {
                        required property string modelData

                        implicitWidth: root.iconSize
                        implicitHeight: root.iconSize

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: parent.modelData
                            font.pixelSize: root.iconSize
                            color: slot.isActive ? Colors.textOnPrimary : Colors.textMuted

                            Behavior on color { CAnim {} }
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: slot.modelData.extra > 0
                    text: "+" + slot.modelData.extra
                    font.pixelSize: Motion.fontSize.tiny
                    font.bold: slot.isActive
                    color: slot.isActive ? Colors.textOnPrimary : Colors.textMuted

                    Behavior on color { CAnim {} }
                }
            }

            StyledText {
                visible: !slot.hasIcons
                anchors.centerIn: parent
                text: modelData.ws.id
                font.pixelSize: Motion.fontSize.body
                font.bold: slot.isActive
                color: slot.isActive ? Colors.textOnPrimary : (modelData.occupied ? Colors.text : Colors.textMuted)

                Behavior on color { CAnim {} }
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
