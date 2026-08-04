import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Keep Awake card
Rectangle {
    id: root

    radius: Motion.rounding.large
    color: Colors.layer
    implicitHeight: row.implicitHeight + 32

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Motion.spacing.xlarge }
        spacing: Motion.spacing.large

        MaterialIcon {
            text: "coffee"
            color: Colors.text
            font.pixelSize: Motion.fontSize.display
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Motion.spacing.micro

            StyledText {
                text: "Keep Awake"
                font.pixelSize: Motion.fontSize.subhead
                font.bold: true
            }

            StyledText {
                text: IdleInhibitState.enabled ? "Preventing sleep mode" : "Sleep as normal"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
            }

            Rectangle {
                Layout.topMargin: Motion.spacing.small
                radius: Motion.rounding.small
                color: Colors.panel
                implicitWidth: activeSinceText.implicitWidth + 16
                implicitHeight: activeSinceText.implicitHeight + 6

                StyledText {
                    id: activeSinceText
                    anchors.centerIn: parent
                    text: IdleInhibitState.enabled
                        ? "Active since " + Qt.formatDateTime(new Date(IdleInhibitState.activeSince), Time.clockFormat)
                        : "Active since —"
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.tiny
                }
            }
        }

        ToggleSwitch {
            Layout.alignment: Qt.AlignVCenter
            checked: IdleInhibitState.enabled
            onToggled: IdleInhibitState.toggle()
        }
    }
}
