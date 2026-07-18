import QtQuick
import Quickshell
import "../../services"
import "../sidebarRight"

// Single session action: round icon button, executes immediately on click
Rectangle {
    id: root

    required property string icon
    required property var command

    implicitWidth: 64
    implicitHeight: 64
    radius: width / 2
    color: hoverArea.containsMouse ? Colors.surface : Colors.background

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        color: Colors.text
        font.pixelSize: 28
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(root.command);
            SessionState.open = false;
        }
    }
}
