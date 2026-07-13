import QtQuick
import Quickshell.Services.SystemTray

// System tray: row of TrayItem icons, reactive to SystemTray.items
Item {
    id: root

    readonly property bool hasItems: SystemTray.items.values.length > 0

    visible: root.hasItems
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Repeater {
            model: SystemTray.items

            TrayItem {
                required property SystemTrayItem modelData
                item: modelData
            }
        }
    }
}
