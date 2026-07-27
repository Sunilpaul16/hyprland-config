import QtQuick
import QtQuick.Layouts
import "../../services"
import "../sidebarRight"

// Dropdown-style control — current value plus a chevron. Opens nothing yet
Rectangle {
    id: root

    property string value
    // Trailing glyph — "expand_more" for a select, "chevron_right" for a nav row
    property string icon: "expand_more"

    signal clicked

    implicitWidth: layout.implicitWidth + 16 * 2
    implicitHeight: 34
    radius: height / 2

    color: hover.containsMouse ? Colors.secondaryContainer : Colors.background

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.value
            color: Colors.text
            font.pixelSize: 14
        }

        MaterialIcon {
            text: root.icon
            color: Colors.outline
            font.pixelSize: 18
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
