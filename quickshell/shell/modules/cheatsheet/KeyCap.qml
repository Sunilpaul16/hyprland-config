import QtQuick
import "../../services"

// Key cap badge
Rectangle {
    id: root

    required property string label

    implicitWidth: Math.max(text.implicitWidth + 14, height)
    implicitHeight: 20
    radius: 6
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Text {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: Colors.text
        font.pixelSize: 11
        font.bold: true
    }
}
