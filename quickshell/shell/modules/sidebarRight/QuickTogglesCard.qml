import QtQuick
import "../../services"

// Quick toggles card (sidebar)
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    implicitHeight: content.implicitHeight + 32

    QuickTogglesRow {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
    }
}
