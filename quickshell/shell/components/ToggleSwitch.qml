import QtQuick
import "../services"

// M3 switch
Rectangle {
    id: root

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 52
    implicitHeight: 32
    radius: height / 2

    color: root.checked ? Colors.primary : Colors.layer
    border.width: root.checked ? 0 : 2
    border.color: Colors.outline

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    // Thumb
    Rectangle {
        id: thumb

        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 6
        width: root.checked ? 24 : 20
        height: width
        radius: width / 2
        color: root.checked ? Colors.textOnPrimary : Colors.outline

        Behavior on x { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
        Behavior on width { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.checked ? "check" : "close"
            color: root.checked ? Colors.primary : Colors.layer
            font.pixelSize: Motion.fontSize.subhead
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
