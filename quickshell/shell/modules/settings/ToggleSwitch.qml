import QtQuick
import "../../services"
import "../sidebarRight"

// M3 switch — the thumb carries a check/cross glyph and grows when on.
// Externally driven: a click only emits toggled(), it never writes `checked`
// itself, so an owner can bind `checked` to config and have the binding
// survive being clicked. Owners that just want local state say
// `onToggled: v => checked = v`
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
        color: root.checked ? Colors.background : Colors.outline

        Behavior on x { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
        Behavior on width { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.checked ? "check" : "close"
            color: root.checked ? Colors.primary : Colors.layer
            font.pixelSize: 14
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
