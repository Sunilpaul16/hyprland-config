import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../services"
import "../../components"

// One Bluetooth device row inside BluetoothDialog.qml (comparison.md #25)
RowLayout {
    id: root

    required property BluetoothDevice device

    spacing: 10

    MaterialIcon {
        text: root.device.connected ? "bluetooth_connected" : "bluetooth"
        color: root.device.connected ? Colors.primary : Colors.textMuted
        font.pixelSize: 18
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.device.name.length > 0 ? root.device.name : root.device.deviceName
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        StyledText {
            visible: root.device.batteryAvailable
            text: Math.round(root.device.battery * 100) + "%"
            color: Colors.textMuted
            font.pixelSize: 11
        }
    }

    // Busy indicator while pairing/connecting
    MaterialIcon {
        visible: root.device.pairing || root.device.state === BluetoothDeviceState.Connecting
        text: "sync"
        color: Colors.textMuted
        font.pixelSize: 15

        RotationAnimation on rotation {
            running: parent.visible
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
        }
    }

    IconAction {
        visible: root.device.connected
        iconName: "bluetooth_disabled"
        onTriggered: root.device.disconnect()
    }

    IconAction {
        visible: root.device.paired && !root.device.connected
        iconName: "check_circle"
        onTriggered: root.device.connect()
    }

    IconAction {
        visible: !root.device.paired
        iconName: "bluetooth_searching"
        onTriggered: root.device.pair()
    }

    IconAction {
        visible: root.device.paired
        iconName: "delete"
        onTriggered: root.device.forget()
    }
}
