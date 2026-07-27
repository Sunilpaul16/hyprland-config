import QtQuick
import QtQuick.Layouts
import "../../services"
import "../sidebarRight"

// Tonal pill — leading icon + label, used for a page's sub-navigation
Rectangle {
    id: root

    property string icon
    property string text
    property bool highlighted: false
    // Matches SettingRow.live — red text flags a pill that goes nowhere yet
    property bool live: false

    signal clicked

    implicitWidth: layout.implicitWidth + 26 * 2
    implicitHeight: 44
    radius: height / 2

    color: root.highlighted || hover.containsMouse ? Colors.secondaryContainer : Colors.surface

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

        Text {
            text: root.text
            color: root.live ? Colors.text : Colors.error
            font.pixelSize: 15
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
