import QtQuick
import "../../services"

// Power icon widget, opens SessionScreen
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\u{23FB}"
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 15

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    // Click to open session screen
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SessionState.open = true
    }
}
