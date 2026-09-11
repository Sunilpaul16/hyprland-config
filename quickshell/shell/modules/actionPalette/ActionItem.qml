import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    required property var modelData
    required property bool isCurrent
    signal activated

    width: ListView.view.width
    height: 58

    Rectangle {
        anchors.fill: parent
        anchors.margins: Motion.spacing.micro
        radius: Motion.rounding.item
        color: root.isCurrent ? Colors.primary : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: Motion.spacing.large
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            text: root.modelData.icon
            color: root.isCurrent ? Colors.textOnPrimary : Colors.primary
            font.pixelSize: Motion.fontSize.xlarge
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 60
            anchors.right: parent.right
            anchors.rightMargin: Motion.spacing.large
            anchors.verticalCenter: parent.verticalCenter
            spacing: Motion.spacing.micro

            StyledText {
                width: parent.width
                text: root.modelData.label
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

        TapHandler { onTapped: root.activated() }
    }
}
