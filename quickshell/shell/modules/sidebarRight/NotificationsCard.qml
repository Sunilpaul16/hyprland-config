import QtQuick
import QtQuick.Layouts
import "../../services"

// Static shell only — no live notification data. The real notification
// history panel is modules/notifications/NotifPanel.qml (bell icon in the
// bar). This card is a visual placeholder pending a decision on whether to
// consolidate the two.
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    implicitHeight: column.implicitHeight + column.anchors.margins * 2

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 16

        Text {
            text: "Notifications"
            color: Colors.text
            font.pixelSize: 15
            font.bold: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            spacing: 12

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "\u{1F515}" // bell with cancellation stroke — glyph stand-in for an illustration
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
    }
}
