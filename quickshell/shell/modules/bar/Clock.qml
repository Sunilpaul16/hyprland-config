import QtQuick
import "../../services"
import "../../components"

// Clock widget: time + date
Item {
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
            color: Colors.textMuted
            font.pixelSize: 14
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.dateStr
            color: Colors.textMuted
            font.pixelSize: 13
        }
    }
}
