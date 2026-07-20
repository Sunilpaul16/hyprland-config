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
    border.width: root.activeFocus ? 2 : 0
    border.color: Colors.primary

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    function activate(): void {
        Quickshell.execDetached(root.command);
        SessionState.open = false;
    }

    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()

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
        onClicked: root.activate()
    }
}
