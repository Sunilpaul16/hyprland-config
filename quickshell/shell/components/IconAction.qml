import QtQuick
import "../services"

// Icon button
Rectangle {
    id: root

    property string iconName: "circle"
    property color iconColor: Colors.text
    property int iconSize: Motion.fontSize.title
    readonly property alias hovered: hoverArea.containsMouse

    signal triggered

    implicitWidth: 24
    implicitHeight: 24
    radius: Motion.rounding.small
    // State layer, not a surface
    color: hoverArea.pressed ? Qt.alpha(Colors.text, 0.16) : (hoverArea.containsMouse ? Qt.alpha(Colors.text, 0.1) : "transparent")
    scale: hoverArea.pressed ? 0.94 : 1

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    Behavior on scale { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.iconName
        color: root.iconColor
        font.pixelSize: root.iconSize
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
