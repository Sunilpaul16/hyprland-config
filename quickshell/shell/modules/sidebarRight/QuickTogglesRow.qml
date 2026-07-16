import QtQuick
import QtQuick.Layouts
import "../../services"

// Wifi/bluetooth/mic pills wired to real state (Wifi/BluetoothStatus/Audio
// singletons). Settings + overflow stay inert placeholders — no
// control-center surface built for them yet. No card background (matches
// caelestia reference) — sits directly on the panel's own backdrop.
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

        TogglePill {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            iconName: Wifi.hardwareAvailable ? (Wifi.enabled ? "wifi" : "wifi_off") : "wifi_off"
            active: Wifi.hardwareAvailable && Wifi.enabled
            enabled: Wifi.hardwareAvailable
            onClicked: Wifi.toggle()
        }

        TogglePill {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            iconName: BluetoothStatus.connected ? "bluetooth_connected" : (BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled")
            active: BluetoothStatus.enabled
            enabled: BluetoothStatus.available
            onClicked: BluetoothStatus.toggle()
        }

        TogglePill {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            iconName: Audio.micMuted ? "mic_off" : "mic"
            active: !Audio.micMuted
            onClicked: Audio.toggleMicMute()
        }

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: Colors.background

            MaterialIcon {
                anchors.centerIn: parent
                text: "settings"
                color: Colors.text
                font.pixelSize: 20
            }
        }

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: Colors.background

            MaterialIcon {
                anchors.centerIn: parent
                text: "more_horiz"
                color: Colors.text
                font.pixelSize: 20
            }
        }

        Item { Layout.fillWidth: true }
    }
}
