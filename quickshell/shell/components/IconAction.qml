import QtQuick
import "../services"

// Icon button
Rectangle {
    id: root

    property string iconName: "circle"
    property color iconColor: Colors.text

    signal triggered

    implicitWidth: 24
    implicitHeight: 24
    radius: Motion.rounding.small
    color: hoverArea.containsMouse ? Colors.panel : "transparent"

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.iconName
        color: root.iconColor
        font.pixelSize: Motion.fontSize.title
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
