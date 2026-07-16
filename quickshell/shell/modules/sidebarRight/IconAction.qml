import QtQuick
import "../../services"

// Small tappable icon button — play/reveal/delete rows in the Recordings
// list, and their inline confirm/cancel state.
Rectangle {
    id: root

    property string iconName: "circle"
    property color iconColor: Colors.text

    signal triggered

    implicitWidth: 24
    implicitHeight: 24
    radius: 8
    color: hoverArea.containsMouse ? Colors.background : "transparent"

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.iconName
        color: root.iconColor
        font.pixelSize: 15
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
