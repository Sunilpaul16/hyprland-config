pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Wifi state singleton
Singleton {
    id: root

    readonly property WifiDevice device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool hardwareAvailable: device !== null
    readonly property bool enabled: Networking.wifiEnabled
    readonly property WifiNetwork activeNetwork: device?.networks?.values.find(n => n.connected) ?? null
    readonly property string networkName: activeNetwork?.name ?? ""

    function toggle(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}
