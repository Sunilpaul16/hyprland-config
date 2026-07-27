import QtQuick
import "../../services"

// M3 slider, display only — `value` is 0..1 and nothing writes it back
Item {
    id: root

    property real value: 0.5

    implicitWidth: 170
    implicitHeight: 26

    readonly property real trackHeight: 6
    readonly property real handleWidth: 4
    readonly property real fillWidth: Math.round((root.width - root.handleWidth - 8) * root.value)

    // Filled track
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.fillWidth
        height: root.trackHeight
        radius: height / 2
        color: Colors.primary
    }

    // Remaining track
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        width: root.width - root.fillWidth - root.handleWidth - 8
        height: root.trackHeight
        radius: height / 2
        color: Colors.outlineVariant
    }

    Rectangle {
        x: root.fillWidth + 4
        anchors.verticalCenter: parent.verticalCenter
        width: root.handleWidth
        height: parent.height
        radius: width / 2
        color: Colors.primary
    }
}
