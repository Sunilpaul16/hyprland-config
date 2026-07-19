import QtQuick
import QtQuick.Layouts
import "../../services"

// Keep Awake card (sidebar)
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
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

            Text {
                text: "Keep Awake"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                text: IdleInhibitState.enabled ? "Preventing sleep mode" : "Sleep as normal"
                color: Colors.textMuted
                font.pixelSize: 12
            }

            Rectangle {
                Layout.topMargin: 6
                radius: 8
                color: Colors.background
                implicitWidth: activeSinceText.implicitWidth + 16
                implicitHeight: activeSinceText.implicitHeight + 6

                Text {
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
            width: 40
            height: 22
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
