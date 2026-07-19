import QtQuick
import QtQuick.Layouts
import "../../services"

// Quick toggles row
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

        // Ethernet (opens NetworkManager's connection editor)
        TogglePill {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            iconName: "lan"
            active: EthernetStatus.connected
            enabled: EthernetStatus.available
            onClicked: EthernetStatus.openSettings()
        }

        // Bluetooth
        TogglePill {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            iconName: BluetoothStatus.connected ? "bluetooth_connected" : (BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled")
            active: BluetoothStatus.enabled
            enabled: BluetoothStatus.available
            onClicked: BluetoothStatus.toggle()
        }

        // Mic
        TogglePill {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            iconName: Audio.micMuted ? "mic_off" : "mic"
            active: !Audio.micMuted
            onClicked: Audio.toggleMicMute()
        }

        // Settings (placeholder)
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

        // Night light
        TogglePill {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            iconName: "bedtime"
            active: NightLightState.enabled
            onClicked: NightLightState.toggle()
        }

        // Do not disturb (placeholder)
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: Colors.background

            MaterialIcon {
                anchors.centerIn: parent
                text: "notifications_off"
                color: Colors.text
                font.pixelSize: 20
            }
        }

        Item { Layout.fillWidth: true }
    }
}
