import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../services"
import "../../components"

// Bluetooth device row
SettingRow {
    id: root

    required property BluetoothDevice device

    live: true
    label: BluetoothStatus.deviceLabel(root.device)
    subtext: BluetoothStatus.deviceStatus(root.device)

    RowLayout {
        spacing: Motion.spacing.normal

        // Busy spinner
        MaterialIcon {
            id: busyIcon
            visible: root.device.pairing || root.device.state === BluetoothDeviceState.Connecting
            text: "sync"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.large

            RotationAnimation on rotation {
                running: busyIcon.visible && !Motion.reduced
                from: 0
                to: 360
                duration: Motion.scaled(1000)
                loops: Animation.Infinite
                onRunningChanged: if (!running) busyIcon.rotation = 0
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
