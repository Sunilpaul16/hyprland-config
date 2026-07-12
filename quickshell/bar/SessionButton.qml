import QtQuick

// Power icon widget, opens SessionScreen
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\u{23FB}"
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 15

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // Click to open session screen
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SessionState.open = true
    }
}
