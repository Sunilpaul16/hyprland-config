import QtQuick
import QtQuick.Layouts
import "../../services"
import "quickToggles"
import "../../components"

// Hidden toggles
ColumnLayout {
    id: root

    required property var models

    signal addRequested(toggleId: string)

    spacing: Motion.spacing.small

    StyledText {
        text: "Hidden"
        color: Colors.textMuted
        font.pixelSize: Motion.fontSize.small
    }

    Flow {
        Layout.fillWidth: true
        spacing: Motion.spacing.normal

        Repeater {
            model: root.models

            Item {
                id: hiddenSlot
                required property QuickToggleModel modelData

                implicitWidth: 40
                implicitHeight: 40

                TogglePill {
                    anchors.fill: parent
                    iconName: hiddenSlot.modelData.icon
                    active: false
                    enabled: false
                    opacity: 0.5
                }

                // Add-back badge
                Rectangle {
                    width: 14
                    height: 14
                    radius: width / 2
                    anchors { top: parent.top; right: parent.right; margins: -2 }
                    color: Colors.primary
                    border.color: Colors.surface
                    border.width: 1.5

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "add"
                        color: Colors.background
                        font.pixelSize: Motion.fontSize.micro
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addRequested(hiddenSlot.modelData.toggleId)
                    }
                }
            }
        }
    }
}
