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
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
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
                color: Colors.background
                implicitWidth: activeSinceText.implicitWidth + 16
                implicitHeight: activeSinceText.implicitHeight + 6

                StyledText {
                    id: activeSinceText
                    anchors.centerIn: parent
                    text: IdleInhibitState.enabled
                        ? "Active since " + Qt.formatDateTime(new Date(IdleInhibitState.activeSince), "hh:mm")
                        : "Active since —"
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.tiny
                }
            }
        }

        // Toggle switch
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 40
            implicitHeight: 22
            radius: height / 2
            color: IdleInhibitState.enabled ? Colors.primary : Colors.outline

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            Rectangle {
                width: 18
                height: 18
                radius: width / 2
                color: Colors.background
                anchors.verticalCenter: parent.verticalCenter
                x: IdleInhibitState.enabled ? parent.width - width - 2 : 2

                Behavior on x { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: IdleInhibitState.toggle()
            }
        }
    }
}
