import QtQuick
import Quickshell.Services.SystemTray
import "../../services"
import "../../components"

// System tray: row of TrayItem icons, reactive to SystemTray.items
Item {
    id: root

    // Status applets that register a tray icon with no user-facing app running — hidden so the pill only reflects real apps like Discord or Steam
    readonly property var hiddenIds: ["nm-applet", "blueman"]

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

    // Start collapsed again next time there's something to hide, rather
    // than resuming pre-expanded once overflow reappears
    onHasOverflowChanged: if (!root.hasOverflow) root.expanded = false

    visible: root.hasItems
    clip: true
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

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
