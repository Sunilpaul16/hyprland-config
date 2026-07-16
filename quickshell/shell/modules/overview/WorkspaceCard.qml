import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

// Single workspace card: background sized to its monitor's aspect ratio
// (accounting for rotated outputs -- this repo's DP-2 runs transform=3),
// workspace number, active-workspace highlight, and live window thumbnails.
Item {
    id: root

    required property var screen
    required property bool active
    required property var slot // HyprlandWorkspace, or {id, isPlaceholder: true}

    readonly property bool isPlaceholder: !!slot.isPlaceholder
    readonly property var wsMonitor: isPlaceholder ? null : slot.monitor
    readonly property var fallbackMonitor: Hyprland.monitorFor(root.screen)
    readonly property var monitor: wsMonitor ?? fallbackMonitor

    readonly property int monTransform: monitor?.lastIpcObject?.transform ?? 0
    readonly property bool monRotated: monTransform % 2 === 1
    readonly property real monLogicalWidth: monitor ? (monRotated ? monitor.height : monitor.width) : 16
    readonly property real monLogicalHeight: monitor ? (monRotated ? monitor.width : monitor.height) : 9

    readonly property bool isActive: !isPlaceholder && slot.active

    width: height * (monLogicalWidth / monLogicalHeight)

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 12
        color: Colors.surface
        border.width: root.isActive ? 2 : 1
        border.color: root.isActive ? Colors.primary : Colors.outline
        clip: true

        // Click empty card area to jump to that workspace. Declared before
        // the thumbnail Repeater so thumbnails stack on top and get first
        // claim on clicks -- this only sees clicks that miss every thumbnail.
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${root.slot.id} })`);
                OverviewState.open = false;
            }
        }

        Text {
            anchors { top: parent.top; left: parent.left; margins: 8 }
            text: root.slot.id
            color: root.isActive ? Colors.primary : Colors.textMuted
            font.pixelSize: 13
            font.bold: root.isActive
            z: 2
        }

        // Live window thumbnails
        Repeater {
            model: root.isPlaceholder ? [] : root.slot.toplevels.values

            OverviewWindowThumb {
                required property var modelData
                toplevel: modelData
                cardWidth: bg.width
                cardHeight: bg.height
                monX: root.monitor?.x ?? 0
                monY: root.monitor?.y ?? 0
                monLogicalWidth: root.monLogicalWidth
                monLogicalHeight: root.monLogicalHeight
                overviewActive: root.active
            }
        }
    }
}
