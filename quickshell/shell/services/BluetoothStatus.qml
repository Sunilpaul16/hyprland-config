pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth state singleton. Named `BluetoothStatus`, not `Bluetooth` — that
// name is already taken by the Quickshell.Bluetooth singleton this wraps.
Singleton {
    id: root

    readonly property bool available: Bluetooth.defaultAdapter !== null
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice connectedDevice: Bluetooth.devices.values.find(d => d.connected) ?? null
    readonly property bool connected: connectedDevice !== null

    function toggle(): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    }
}
