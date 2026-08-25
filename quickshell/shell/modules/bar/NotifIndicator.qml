import QtQuick
import "../../services"
import "../../components"

// Unread bell
Item {
    id: root

    readonly property bool active: DndState.enabled || Notifs.unread > 0

    // Match the tray icon hit box. The badge overlays this slot instead of
    // widening it and pushing the bell away from adjacent tray icons.
    implicitWidth: active ? 26 : 0
    implicitHeight: 26
    visible: implicitWidth > 0
    clip: true

    Behavior on implicitWidth {
        Anim { type: "effectsFast" }
    }

    StyledText {
        id: icon
        anchors.centerIn: parent
        // Escapes, not literals
        text: DndState.enabled ? "\uf1f6" : "\uf0f3" // bell-slash / bell
        font.family: Fonts.glyphFamily
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: Motion.fontSize.label

        Behavior on color { CAnim {} }
    }

    // Unread count
    Rectangle {
        anchors { right: parent.right; top: parent.top; topMargin: 1 }
        visible: !DndState.enabled && Notifs.unread > 0
        implicitWidth: Math.max(countText.implicitWidth + 4, height)
        implicitHeight: countText.implicitHeight + 1
        radius: height / 2
        color: Colors.primary

        StyledText {
            id: countText
            anchors.centerIn: parent
            text: Notifs.unread > 9 ? "9+" : Notifs.unread
            color: Colors.textOnPrimary
            font.pixelSize: Motion.fontSize.micro
            font.bold: true
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SidebarRightState.toggle()
    }
}
