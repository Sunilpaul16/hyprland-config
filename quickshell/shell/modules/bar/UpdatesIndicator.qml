import QtQuick
import "../../services"
import "../../components"

// Update count
Item {
    id: root

    readonly property bool active: Config.updates.showInBar && Updates.total > 0

    // Collapses to zero
    implicitWidth: active ? icon.implicitWidth + count.implicitWidth + 4 : 0
    implicitHeight: icon.implicitHeight
    visible: implicitWidth > 0
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
    }

    MaterialIcon {
        id: icon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "update"
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: Motion.fontSize.title

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    StyledText {
        id: count

        anchors.left: icon.right
        anchors.leftMargin: Motion.spacing.tiny
        anchors.verticalCenter: parent.verticalCenter
        text: Updates.total > 99 ? "99+" : Updates.total
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: Motion.fontSize.body

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SettingsState.openPage("updates")
    }
}
