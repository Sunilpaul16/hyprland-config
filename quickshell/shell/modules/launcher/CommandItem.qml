import QtQuick
import "../../services"
import "../../components"

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
        anchors.margins: Motion.spacing.micro
        radius: Motion.rounding.item
        color: root.isCurrent ? Colors.primary : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        // Icon + title/description
        Row {
            anchors.fill: parent
            anchors.leftMargin: Motion.spacing.large
            anchors.rightMargin: Motion.spacing.large
            spacing: Motion.spacing.large

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.modelData.icon
                font.pixelSize: Motion.fontSize.xlarge
                width: 36
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 36 - parent.spacing
                spacing: Motion.spacing.micro

                StyledText {
                    width: parent.width
                    text: root.modelData.title
                    color: root.isCurrent ? Colors.textOnPrimary : Colors.text
                    font.pixelSize: Motion.fontSize.subhead
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: root.modelData.description
                    color: root.isCurrent ? Colors.textOnPrimary : Colors.textMuted
                    font.pixelSize: Motion.fontSize.body
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
