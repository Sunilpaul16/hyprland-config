import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../services"

// Overflow list for tray items hidden from the bar row via middle-click (comparison.md #35)
Loader {
    id: root

    required property Item anchorItem
    property bool shown: false
    property var items: []

    signal toggleHiddenRequested(string itemId)

    active: root.shown

    sourceComponent: PopupWindow {
        visible: true
        anchor {
            window: root.anchorItem.QsWindow.window
            item: root.anchorItem
            edges: Edges.Bottom
            gravity: Edges.Bottom
            margins.top: 8
        }

        color: "transparent"
        implicitWidth: Math.max(60, grid.implicitWidth + 24)
        implicitHeight: grid.implicitHeight + 24

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Colors.surface
            border.width: 1
            border.color: Colors.outline

            GridLayout {
                id: grid
                anchors.centerIn: parent
                columns: Math.max(1, Math.min(4, root.items.length))
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: root.items

                    TrayItem {
                        required property SystemTrayItem modelData
                        item: modelData
                        onToggleHiddenRequested: root.toggleHiddenRequested(modelData.id)
                    }
                }
            }
        }
    }
}
