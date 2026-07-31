import QtQuick
import "../../services"
import "../../components"

// Sidebar toggle icon widget, opens right sidebar
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    StyledText {
        id: icon
        anchors.centerIn: parent
        text: "\u{25A4}" // sidebar-panel glyph
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 14

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    // Click to toggle sidebar
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SidebarRightState.toggle()
    }
}
