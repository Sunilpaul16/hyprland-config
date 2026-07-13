import QtQuick

// Clock widget: time + date
Item {
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.timeStr
            color: Colors.text
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "·"
            color: Colors.textMuted
            font.pixelSize: 14
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.dateStr
            color: Colors.textMuted
            font.pixelSize: 13
        }
    }
}
