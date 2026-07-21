import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../../services"
import "../sidebarRight"

// System tray: row of TrayItem icons, middle-click one to hide it into the overflow popup (comparison.md #35)
Item {
    id: root

    function isHidden(item: SystemTrayItem): bool {
        return Persistent.hiddenTrayIds.includes(item.id.toLowerCase());
    }

    function toggleHidden(itemId: string): void {
        const id = itemId.toLowerCase();
        if (Persistent.hiddenTrayIds.includes(id))
            Persistent.hiddenTrayIds = Persistent.hiddenTrayIds.filter(i => i !== id);
        else
            Persistent.hiddenTrayIds = [...Persistent.hiddenTrayIds, id];
    }

    readonly property var visibleItems: SystemTray.items.values.filter(item => !root.isHidden(item))
    readonly property var overflowItems: SystemTray.items.values.filter(item => root.isHidden(item))
    readonly property bool hasItems: root.visibleItems.length > 0 || root.overflowItems.length > 0

    property bool overflowOpen: false

    visible: root.hasItems
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Repeater {
            model: root.visibleItems

            TrayItem {
                required property SystemTrayItem modelData
                item: modelData
                onToggleHiddenRequested: root.toggleHidden(modelData.id)
            }
        }

        // Overflow toggle — only shown once something's actually hidden there
        Item {
            id: overflowBtn
            visible: root.overflowItems.length > 0
            implicitWidth: 18
            implicitHeight: 18

            MaterialIcon {
                anchors.centerIn: parent
                text: "more_horiz"
                color: (overflowHover.containsMouse || root.overflowOpen) ? Colors.text : Colors.textMuted
                font.pixelSize: 16
            }

            MouseArea {
                id: overflowHover
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.overflowOpen = !root.overflowOpen
            }
        }
    }

    TrayOverflowPopup {
        anchorItem: overflowBtn
        shown: root.overflowOpen
        items: root.overflowItems
        onToggleHiddenRequested: itemId => root.toggleHidden(itemId)
    }
}
