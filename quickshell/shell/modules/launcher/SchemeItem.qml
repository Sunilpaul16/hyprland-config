import QtQuick
import "../../services"
import "../../components"

// Scheme list item
Item {
    id: root

    required property var modelData
    required property bool isCurrent

    readonly property bool isDynamic: root.modelData.isDynamic === true
    readonly property bool active: root.isDynamic ? !Theme.usingPreset : root.modelData.id === Theme.source

    width: ListView.view.width
    height: 56

    signal activated

    // Row background
    Rectangle {
        anchors.fill: parent
        anchors.margins: Motion.spacing.micro
        radius: Motion.rounding.item
        color: root.isCurrent ? Colors.primary : "transparent"

        Behavior on color { CAnim {} }

        Row {
            anchors.fill: parent
            anchors.leftMargin: Motion.spacing.large
            anchors.rightMargin: Motion.spacing.large
            spacing: Motion.spacing.large

            // Two-tone preview
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: width / 2
                color: root.isDynamic ? Colors.surface : root.modelData.surface
                border.width: 1
                border.color: root.isDynamic ? Colors.outline : root.modelData.outline

                // Accent half
                Item {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    clip: true

                    Rectangle {
                        width: parent.width * 2
                        height: parent.height
                        x: -parent.width
                        radius: height / 2
                        color: root.isDynamic ? Colors.primary : root.modelData.primary
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32 - parent.spacing
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
                    text: root.active ? `${root.modelData.description} · in use` : root.modelData.description
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
