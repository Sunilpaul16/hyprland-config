import QtQuick

// Notification bell + count badge, opens NotifPanel
Item {
    id: root

    readonly property int count: Notifs.list.filter(n => !n.closed).length

    implicitWidth: bellIcon.implicitWidth
    implicitHeight: bellIcon.implicitHeight

    Text {
        id: bellIcon
        anchors.centerIn: parent
        text: "\u{1F514}" // bell
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 14

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // Unread-count badge
    Rectangle {
        visible: root.count > 0
        anchors.right: bellIcon.right
        anchors.top: bellIcon.top
        anchors.rightMargin: -5
        anchors.topMargin: -5
        radius: height / 2
        color: Colors.error
        implicitWidth: Math.max(14, badgeText.implicitWidth + 6)
        implicitHeight: 14

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.count > 99 ? "99+" : root.count
            color: Colors.textOnError
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotifPanelState.toggle()
    }
}
