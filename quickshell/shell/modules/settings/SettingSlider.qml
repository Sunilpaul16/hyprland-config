import QtQuick
import "../../services"

// M3 slider
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0.5
    // Step size
    property real stepSize: 0

    signal moved(real v)

    implicitWidth: 170
    implicitHeight: 26

    readonly property real trackHeight: 6
    readonly property real handleWidth: 4
    readonly property real span: root.to - root.from
    // Clamped position
    readonly property real position: root.span === 0 ? 0 : Math.max(0, Math.min(1, (root.value - root.from) / root.span))
    readonly property real travel: root.width - root.handleWidth - 8
    readonly property real fillWidth: Math.round(root.travel * root.position)

    function valueAt(px: real): real {
        const ratio = Math.max(0, Math.min(1, (px - root.handleWidth / 2) / root.travel));
        const raw = root.from + ratio * root.span;
        return root.stepSize > 0 ? Math.round(raw / root.stepSize) * root.stepSize : raw;
    }

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
        width: root.travel - root.fillWidth
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

        scale: drag.pressed ? 1.4 : 1

        Behavior on scale { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    MouseArea {
        id: drag

        anchors.fill: parent
        // Grabbable handle
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => root.moved(root.valueAt(mouse.x))
        onPositionChanged: mouse => {
            if (drag.pressed)
                root.moved(root.valueAt(mouse.x));
        }
    }
}
