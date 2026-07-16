import QtQuick
import Quickshell
import "../../services"

// Single tray-menu entry (item or separator)
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
        anchors.margins: 4
        height: 1
        color: Colors.outline
        opacity: 0.5
    }

    // Regular item
    Rectangle {
        visible: !root.isSep
        anchors.fill: parent
        radius: 6
        color: hoverArea.containsMouse && root.entry.enabled ? Colors.surface : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 8
            opacity: root.entry.enabled ? 1 : 0.4

            // Checkbox / radio glyph
            Text {
                visible: root.entry.buttonType !== QsMenuButtonType.None
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (root.entry.buttonType === QsMenuButtonType.RadioButton)
                        return root.entry.checkState === Qt.Checked ? "◉" : "○";
                    return root.entry.checkState === Qt.Checked ? "☑" : "☐";
                }
                color: Colors.textMuted
                font.pixelSize: 12
            }

            // App-provided icon, rendered as-is
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
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.entry.text
                color: Colors.text
                font.pixelSize: 13
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 220)
            }

            // Submenu indicator (not expandable this pass)
            Text {
                visible: root.entry.hasChildren
                anchors.verticalCenter: parent.verticalCenter
                text: "▸"
                color: Colors.textMuted
                font.pixelSize: 10
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
