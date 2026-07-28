import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"

// App list item
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
        radius: Motion.rounding.item
        color: root.isCurrent ? Colors.primary : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        // Icon + name/comment
        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: Quickshell.iconPath(root.modelData.icon, "image-missing")
                implicitSize: 36
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 36 - parent.spacing
                spacing: 2

                Text {
                    width: parent.width
                    text: root.modelData.name
                    color: root.isCurrent ? Colors.background : Colors.text
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.modelData.comment || root.modelData.genericName || ""
                    color: root.isCurrent ? Colors.background : Colors.textMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }
        }
    }

    // Activate on tap
    TapHandler {
        onTapped: root.activated()
    }
}
