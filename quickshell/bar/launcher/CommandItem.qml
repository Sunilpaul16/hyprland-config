import QtQuick
import "../"

// One row in the ">" command list: an emoji glyph in place of a real app
// icon (no MaterialIcon-style font is set up in this project), name, and
// description underneath — same shape as AppItem so switching between the
// two modes doesn't jump around visually.
Item {
    id: root

    required property var modelData
    required property bool isCurrent

    width: ListView.view.width
    height: 56

    signal activated

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: root.isCurrent ? Colors.primary : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.modelData.icon
                font.pixelSize: 22
                width: 36
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 36 - parent.spacing
                spacing: 2

                Text {
                    width: parent.width
                    text: root.modelData.title
                    color: root.isCurrent ? Colors.background : Colors.text
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.modelData.description
                    color: root.isCurrent ? Colors.background : Colors.textMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }

    TapHandler {
        onTapped: root.activated()
    }
}
