pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Wifi state singleton — wraps Quickshell's native NetworkManager binding
// directly (no nmcli shelling required). `hardwareAvailable` gates the
// toggle on machines with no wifi radio (this desktop is ethernet-only).
// Note: Networking.wifiHardwareEnabled is a rfkill hard-block flag, not a
// presence check — it reads true even with zero wifi devices (NetworkManager
// can't hard-block hardware that doesn't exist). Device presence is the only
// reliable "is there a wifi radio" signal.
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
