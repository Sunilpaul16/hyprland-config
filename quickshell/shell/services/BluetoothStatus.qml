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

    // Whether other machines can find this one — distinct from `discovering`,
    // which is this adapter scanning outward
    readonly property bool discoverable: Bluetooth.defaultAdapter?.discoverable ?? false

    readonly property string adapterName: Bluetooth.defaultAdapter?.name ?? ""

    function toggle(): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    }

    function setDiscovering(value: bool): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.discovering = value;
    }

    function setDiscoverable(value: bool): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.discoverable = value;
    }

    // "Connected · 80%" / "Pairing…" / "Paired" / "Not paired"
    function deviceStatus(device): string {
        if (!device)
            return "";
        if (device.pairing)
            return "Pairing…";
        if (device.connected)
            return device.batteryAvailable ? `Connected · ${Math.round(device.battery * 100)}%` : "Connected";
        return device.paired ? "Paired" : "Not paired";
    }

    function deviceLabel(device): string {
        return device?.name?.length > 0 ? device.name : (device?.deviceName ?? "Unknown device");
    }
}
