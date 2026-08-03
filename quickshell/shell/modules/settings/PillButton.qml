import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Tonal pill
Rectangle {
    id: root

    property string icon
    property string text
    property bool highlighted: false
    // Mock flag
    property bool live: false

    signal clicked

    implicitWidth: layout.implicitWidth + 26 * 2
    implicitHeight: 44
    radius: height / 2

    color: root.highlighted || hover.containsMouse ? Colors.secondaryContainer : Colors.layer

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    scale: hover.pressed ? 0.96 : 1

    Behavior on scale { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 9

        MaterialIcon {
            text: root.icon
            color: root.live ? Colors.text : Colors.error
            font.pixelSize: 19
        }

        StyledText {
            text: root.text
            color: root.live ? Colors.text : Colors.error
            font.pixelSize: Motion.fontSize.title
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
