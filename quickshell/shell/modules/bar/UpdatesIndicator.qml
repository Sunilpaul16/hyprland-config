import QtQuick
import "../../services"
import "../../components"

// Pending-update count, hidden while there is nothing to report
Item {
    id: root

    readonly property bool active: Config.updates.showInBar && Updates.total > 0

    // Collapses to zero width rather than just hiding, so the bar's RowLayout
    // reclaims the space — same approach as NotifIndicator
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
        font.pixelSize: 15

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    StyledText {
        id: count

        anchors.left: icon.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: Updates.total > 99 ? "99+" : Updates.total
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 12

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SettingsState.currentPageIdx = 4; // Updates, per Content.qml's pageModel
            ScreenOwner.claim(SettingsState);
            SettingsState.open = true;
        }
    }
}
