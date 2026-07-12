import QtQuick


Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: Time.timeStr
        color: Colors.text
        font.pixelSize: 16
        font.bold: true
    }
}
