import QtQuick
import "../../services"
import "../../components"

// Unread bell
Item {
    id: root

    readonly property bool active: DndState.enabled || Notifs.unread > 0

    // Extra count width
    implicitWidth: active ? icon.implicitWidth + 7 : 0
    implicitHeight: icon.implicitHeight
    visible: implicitWidth > 0
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
    }

    StyledText {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        // Escapes, not literals
        text: DndState.enabled ? "\uf1f6" : "\uf0f3" // bell-slash / bell
        font.family: Fonts.glyphFamily
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: Motion.fontSize.label

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
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
