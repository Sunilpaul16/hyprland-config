import QtQuick
import Quickshell.Services.SystemTray
import "../../services"
import "../../components"

// System tray
Item {
    id: root

    // Hidden applet ids
    readonly property var hiddenIds: Config.bar.trayHidden.split(",").map(s => s.trim().toLowerCase()).filter(s => s.length > 0)

    function isHidden(item: SystemTrayItem): bool {
        return root.hiddenIds.includes(item.id.toLowerCase());
    }

    readonly property var visibleItems: SystemTray.items.values.filter(item => !root.isHidden(item))
    readonly property bool hasItems: root.visibleItems.length > 0

    readonly property int maxVisible: 3
    readonly property var alwaysVisibleItems: root.visibleItems.slice(0, root.maxVisible)
    readonly property var overflowItems: root.visibleItems.slice(root.maxVisible)
    readonly property bool hasOverflow: root.overflowItems.length > 0
    readonly property var displayedItems: root.expanded ? root.visibleItems : root.alwaysVisibleItems

    property bool expanded: false

    // Recollapse on change
    onHasOverflowChanged: if (!root.hasOverflow) root.expanded = false

    visible: root.hasItems
    clip: true
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Behavior on implicitWidth {
        Anim {}
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Motion.spacing.micro

        Repeater {
            model: root.displayedItems

            TrayItem {
                required property SystemTrayItem modelData
                item: modelData
            }
        }

        // Overflow toggle
        Item {
            id: overflowBtn
            visible: root.hasOverflow
            implicitWidth: 26
            implicitHeight: 26

            MaterialIcon {
                anchors.centerIn: parent
                text: root.expanded ? "chevron_right" : "chevron_left"
                color: overflowHover.containsMouse ? Colors.text : Colors.textMuted
                font.pixelSize: Motion.fontSize.large
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
