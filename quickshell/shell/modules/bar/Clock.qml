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
        spacing: Motion.spacing.small

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.timeStr
            font.pixelSize: Motion.fontSize.large
            font.bold: true
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "·"
            color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: Motion.fontSize.subhead

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.dateStr
            color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: Motion.fontSize.label

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
