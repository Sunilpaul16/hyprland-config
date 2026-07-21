pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth


// Bluetooth state singleton
Singleton {
    id: root

    readonly property bool available: Bluetooth.defaultAdapter !== null
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice connectedDevice: Bluetooth.devices.values.find(d => d.connected) ?? null
    readonly property bool connected: connectedDevice !== null

    // Grouped for BluetoothDialog.qml — device.connected/paired come straight from bluez
    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var pairedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected)
    readonly property var availableDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected)

    readonly property bool discovering: Bluetooth.defaultAdapter?.discovering ?? false

    function toggle(): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    }

    function setDiscovering(value: bool): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.discovering = value;
    }
}
