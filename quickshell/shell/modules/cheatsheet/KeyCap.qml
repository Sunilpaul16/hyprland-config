import QtQuick
import "../../services"
import "../../components"

// Key cap badge
Rectangle {
    id: root

    required property string label

    implicitWidth: Math.max(text.implicitWidth + 14, height)
    implicitHeight: 20
    radius: Motion.rounding.small
    color: Colors.layer
    border.width: 1
    border.color: Colors.outline

    StyledText {
        id: text
        anchors.centerIn: parent
        text: root.label
        font.pixelSize: 11
        font.bold: true
    }//
}
