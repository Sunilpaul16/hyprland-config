import QtQuick
import "../../services"

// Quick toggles card (sidebar)
Rectangle {
    id: root

    radius: Motion.rounding.large
    color: Colors.layer
    implicitHeight: content.implicitHeight + 32

    QuickTogglesRow {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
    }
}
