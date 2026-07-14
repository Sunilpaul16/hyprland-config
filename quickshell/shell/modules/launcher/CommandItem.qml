import QtQuick
import "../../services"

// Command list item
Item {
    id: root

    required property var modelData
    required property bool isCurrent

    width: ListView.view.width
    height: 56

    signal activated

    // Row background
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: root.isCurrent ? Colors.primary : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        // Icon + title/description
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

    // Activate on tap
    TapHandler {
        onTapped: root.activated()
    }
}
