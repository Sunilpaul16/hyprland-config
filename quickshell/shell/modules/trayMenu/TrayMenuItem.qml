import QtQuick
import Quickshell
import "../../services"
import "../../components"

// Menu entry
Item {
    id: root

    required property var entry

    readonly property bool isSep: root.entry.isSeparator

    implicitHeight: isSep ? 9 : row.implicitHeight + 10
    implicitWidth: isSep ? 0 : row.implicitWidth + 20

    // Separator
    Rectangle {
        visible: root.isSep
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Motion.spacing.tiny
        height: 1
        color: Colors.outline
        opacity: 0.5
    }

    // Regular item
    Rectangle {
        visible: !root.isSep
        anchors.fill: parent
        radius: Motion.rounding.tiny
        color: hoverArea.containsMouse && root.entry.enabled ? Colors.layer : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Motion.spacing.medium
            anchors.right: parent.right
            anchors.rightMargin: Motion.spacing.medium
            spacing: Motion.spacing.normal
            opacity: root.entry.enabled ? 1 : 0.4

            // Check glyph
            StyledText {
                visible: root.entry.buttonType !== QsMenuButtonType.None
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (root.entry.buttonType === QsMenuButtonType.RadioButton)
                        return root.entry.checkState === Qt.Checked ? "◉" : "○";
                    return root.entry.checkState === Qt.Checked ? "☑" : "☐";
                }
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
            }

            // App icon
            Image {
                visible: root.entry.icon.length > 0
                anchors.verticalCenter: parent.verticalCenter
                source: root.entry.icon
                width: 14
                height: 14
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            // Entry label
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.entry.text
                font.pixelSize: Motion.fontSize.label
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 220)
            }

            // Submenu indicator
            StyledText {
                visible: root.entry.hasChildren
                anchors.verticalCenter: parent.verticalCenter
                text: "▸"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.tiny
            }
        }

        // Click to trigger
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            enabled: root.entry.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.entry.triggered();
                TrayMenuState.close();
            }
        }
    }
}
