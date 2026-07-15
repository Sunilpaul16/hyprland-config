import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../notifications"

// Live notification history — same Notifs singleton and NotifCard delegate
// modules/notifications/NotifPanel.qml (bell icon in the bar) uses, so both
// surfaces share one data source and one per-item look instead of drifting.
Rectangle {
    id: root

    readonly property int maxListHeight: 300

    radius: 18
    color: Colors.surface
    implicitHeight: column.implicitHeight + column.anchors.margins * 2

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Colors.text
                font.pixelSize: 15
                font.bold: true
            }

            Rectangle {
                visible: Notifs.list.length > 0
                radius: 8
                color: clearArea.containsMouse ? Colors.outline : Colors.background
                implicitWidth: clearText.implicitWidth + 20
                implicitHeight: clearText.implicitHeight + 12

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: Colors.text
                    font.pixelSize: 12
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            spacing: 12
            visible: Notifs.list.length === 0

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "notifications_off"
                color: Colors.textMuted
                font.pixelSize: 48
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No Notifications"
                color: Colors.textMuted
                font.pixelSize: 13
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            visible: Notifs.list.length > 0
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            interactive: contentHeight > height
            spacing: 8
            clip: true

            model: ScriptModel {
                values: Notifs.list.filter(n => !n.closed)
            }

            delegate: NotifCard {
                width: list.width
            }
        }
    }
}
