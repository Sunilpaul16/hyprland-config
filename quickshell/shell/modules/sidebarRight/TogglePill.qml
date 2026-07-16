import QtQuick
import "../../services"

// Reusable 40x40 icon pill for Quick Toggles. Filled with Colors.primary
// when `active`; dimmed (via Item's built-in `enabled`) when the underlying
// hardware/service isn't available (e.g. wifi on an ethernet-only box).
Rectangle {
    id: root

    required property string iconName
    property bool active: false

    signal clicked

    implicitWidth: 40
    implicitHeight: 40
    radius: 12
    color: root.active ? Colors.primary : (hoverArea.containsMouse ? Colors.surface : Colors.background)
    opacity: root.enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.iconName
        color: root.active ? Colors.background : Colors.text
        font.pixelSize: 20

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
