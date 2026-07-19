import QtQuick
import Quickshell.Services.SystemTray

// System tray: row of TrayItem icons, reactive to SystemTray.items
Item {
    id: root

    // Status applets (network/bluetooth managers) that register a tray icon
    // even with no user-facing background app running; hide them so the
    // pill only reflects real apps like Discord or Steam
    readonly property var hiddenIds: ["nm-applet", "blueman"]

    function isHidden(item: SystemTrayItem): bool {
        return root.hiddenIds.includes(item.id.toLowerCase());
    }

    readonly property var visibleItems: SystemTray.items.values.filter(item => !root.isHidden(item))
    readonly property bool hasItems: root.visibleItems.length > 0

    visible: root.hasItems
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Repeater {
            model: root.visibleItems

            TrayItem {
                required property SystemTrayItem modelData
                item: modelData
            }
        }
    }
}
