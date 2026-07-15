import QtQuick
import "../../services"

// Right sidebar toggle (Notifications/Keep Awake/Screen Recorder/Quick
// Toggles panel) — separate from NotifButton, which stays wired to the
// existing notification history panel (NotifPanelState/NotifPanel).
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
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
