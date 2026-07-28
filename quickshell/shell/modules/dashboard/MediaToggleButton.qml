import QtQuick
import "../../services"
import "../../components"

// Shuffle/loop toggle — active-fill pill, same treatment as sidebarRight's TogglePill
Rectangle {
    id: toggleBtn

    required property string iconName
    property bool active: false
    signal clicked()

    implicitWidth: icon.implicitWidth + 14
    implicitHeight: icon.implicitHeight + 14
    radius: implicitHeight / 2
    color: toggleBtn.active ? Colors.primary : (area.containsMouse ? Colors.layer : "transparent")

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: toggleBtn.iconName
        font.pixelSize: 16
        color: toggleBtn.active ? Colors.background : Colors.textMuted

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleBtn.clicked()
    }
}
