import QtQuick
import "../../services"
import "../../components"

// Clock widget
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
            color: Colors.readable(Colors.primary)
            font.pixelSize: Motion.fontSize.large
            font.bold: true

            Behavior on color { CAnim {} }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "·"
            color: Colors.readable(Colors.primary)
            font.pixelSize: Motion.fontSize.large
            font.bold: true

            Behavior on color { CAnim {} }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.dateStr
            color: Colors.readable(Colors.primary)
            font.pixelSize: Motion.fontSize.large
            font.bold: true

            Behavior on color { CAnim {} }
        }
    }
}
