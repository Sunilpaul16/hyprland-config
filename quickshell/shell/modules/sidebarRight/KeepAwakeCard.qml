import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Keep Awake card (sidebar)
Rectangle {
    id: root

    radius: Motion.rounding.large
    color: Colors.layer
    implicitHeight: row.implicitHeight + 32

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        MaterialIcon {
            text: "coffee"
            color: Colors.text
            font.pixelSize: 20
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: "Keep Awake"
                font.pixelSize: 14
                font.bold: true
            }

            StyledText {
                text: IdleInhibitState.enabled ? "Preventing sleep mode" : "Sleep as normal"
                color: Colors.textMuted
                font.pixelSize: 12
            }

            Rectangle {
                Layout.topMargin: 6
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
                    font.pixelSize: 10
                }
            }
        }

        // Keep Awake toggle switch
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
