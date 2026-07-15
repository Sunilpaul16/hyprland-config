import QtQuick
import QtQuick.Layouts
import "../../services"

// Static shell only — inert icon pills, no NetworkManager/bluez wiring yet.
// No card background (matches caelestia reference) — sits directly on the
// panel's own backdrop.
ColumnLayout {
    id: root

    spacing: 12

    Text {
        text: "Quick Toggles"
        color: Colors.text
        font.pixelSize: 15
        font.bold: true
    }

    // Icon row
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: ["wifi", "bluetooth", "mic", "settings", "more_horiz"]

            Rectangle {
                required property string modelData

                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 12
                color: Colors.background

                MaterialIcon {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: Colors.text
                    font.pixelSize: 20
                }
            }
        }

        Item { Layout.fillWidth: true }
    }
}
