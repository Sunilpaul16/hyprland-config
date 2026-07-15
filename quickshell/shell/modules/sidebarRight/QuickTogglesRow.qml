import QtQuick
import QtQuick.Layouts
import "../../services"

// Static shell only — inert icon pills, no NetworkManager/bluez wiring yet.
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    implicitHeight: column.implicitHeight + 32

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        Text {
            text: "Quick Toggles"
            color: Colors.text
            font.pixelSize: 15
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: ["\u{1F4F6}", "BT", "\u{1F399}", "\u{2699}", "\u{22EF}"] // wifi, bluetooth, mic, settings, more

                Rectangle {
                    required property string modelData

                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 12
                    color: Colors.background

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        color: Colors.text
                        font.pixelSize: parent.modelData.length > 1 && parent.modelData !== "\u{22EF}" ? 10 : 15
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }
    }
}
