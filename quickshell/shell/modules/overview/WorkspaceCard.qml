import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

// Single workspace card (real or placeholder)
Item {
    id: root

    required property var screen
    required property bool active
    required property var slot // HyprlandWorkspace, or {id, isPlaceholder: true}
    required property Item overviewContent

    readonly property bool isPlaceholder: !!slot.isPlaceholder
    readonly property var wsMonitor: isPlaceholder ? null : slot.monitor
    readonly property var fallbackMonitor: Hyprland.monitorFor(root.screen)
    readonly property var monitor: wsMonitor ?? fallbackMonitor

    readonly property int monTransform: monitor?.lastIpcObject?.transform ?? 0
    readonly property bool monRotated: monTransform % 2 === 1
    readonly property real monLogicalWidth: monitor ? (monRotated ? monitor.height : monitor.width) : 16
    readonly property real monLogicalHeight: monitor ? (monRotated ? monitor.width : monitor.height) : 9

    readonly property bool isFocused: !isPlaceholder && slot.focused

    width: height * (monLogicalWidth / monLogicalHeight)

    // Card background
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 12
        color: Colors.layer
        border.width: dropArea.containsDrag ? 3 : (root.isFocused ? 2 : 1)
        border.color: dropArea.containsDrag || root.isFocused ? Colors.primary : Colors.outline
        clip: true

        // Click to switch workspace
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${root.slot.id} })`);
                OverviewState.open = false;
            }
        }

        // Drag-to-move drop target
        DropArea {
            id: dropArea
            anchors.fill: parent
            keys: ["overview-window"]
            onDropped: drop => {
                drop.accept();
                root.overviewContent.dragTargetWorkspace = root.slot.id;
            }
        }

        Text {
            anchors { top: parent.top; left: parent.left; margins: 8 }
            text: root.slot.id
            color: root.isFocused ? Colors.primary : Colors.textMuted
            font.pixelSize: 13
            font.bold: root.isFocused
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
                overviewContent: root.overviewContent
                sourceWorkspaceId: root.slot.id
            }
        }
    }
}
