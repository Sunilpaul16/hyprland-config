import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"
import "../../components"

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
        anchors.margins: Motion.spacing.micro
        radius: Motion.rounding.item
        color: root.isCurrent ? Colors.primary : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        // Icon + name/comment
        Row {
            anchors.fill: parent
            anchors.leftMargin: Motion.spacing.large
            anchors.rightMargin: Motion.spacing.large
            spacing: Motion.spacing.large

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: Quickshell.iconPath(root.modelData.icon, "image-missing")
                implicitSize: 36
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 36 - parent.spacing
                spacing: Motion.spacing.micro

                StyledText {
                    width: parent.width
                    text: root.modelData.name
                    color: root.isCurrent ? Colors.textOnPrimary : Colors.text
                    font.pixelSize: Motion.fontSize.subhead
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: root.modelData.comment || root.modelData.genericName || ""
                    color: root.isCurrent ? Colors.textOnPrimary : Colors.textMuted
                    font.pixelSize: Motion.fontSize.body
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
