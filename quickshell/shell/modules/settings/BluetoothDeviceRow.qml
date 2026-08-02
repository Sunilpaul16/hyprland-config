import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../services"
import "../../components"

// One Bluetooth device as a settings row — shares the service and bluez calls with the sidebar's BluetoothDeviceItem, not the presentation
SettingRow {
    id: root

    required property BluetoothDevice device

    live: true
    label: BluetoothStatus.deviceLabel(root.device)
    subtext: BluetoothStatus.deviceStatus(root.device)

    RowLayout {
        spacing: 8

        // Spinner while bluez works — pair and connect are both slow enough
        // to look like nothing happened
        MaterialIcon {
            visible: root.device.pairing || root.device.state === BluetoothDeviceState.Connecting
            text: "sync"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.large

            RotationAnimation on rotation {
                running: parent.visible
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }

        SelectPill {
            visible: root.device.connected
            value: "Disconnect"
            icon: "bluetooth_disabled"
            onClicked: root.device.disconnect()
        }

        SelectPill {
            visible: root.device.paired && !root.device.connected
            value: "Connect"
            icon: "bluetooth_connected"
            onClicked: root.device.connect()
        }

        SelectPill {
            visible: !root.device.paired
            value: "Pair"
            icon: "add_link"
            onClicked: root.device.pair()
        }

        IconAction {
            visible: root.device.paired
            iconName: "delete"
            iconColor: Colors.textMuted
            onTriggered: root.device.forget()
        }
    }
}
