import QtQuick
import "../../services"
import "../../components"

// Clock widget: time + date, opens the right sidebar on click
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.timeStr
            font.pixelSize: 16
            font.bold: true
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "·"
            color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: 14

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.dateStr
            color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: 13

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }
    }

    // Click to toggle the right sidebar
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SidebarRightState.toggle()
    }
}
