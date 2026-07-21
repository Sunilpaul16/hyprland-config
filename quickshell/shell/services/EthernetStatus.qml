pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wired (ethernet) link state via nmcli — Quickshell.Networking's DeviceType
// enum only has None/Wifi (see quickshell-network.qmltypes), no ethernet
// device type, so there's no native Quickshell binding for this
Singleton {
    id: root

    property bool available: false
    property bool connected: false
    property string interfaceName: ""

    function refresh(): void {
        statusProc.running = true;
    }

    // Launch NetworkManager's connection editor — same "Edit Connections"
    // target nm-applet's tray menu used to open before it got filtered
    // out of the tray (see Tray.qml/Persistent.hiddenTrayIds)
    function openSettings(): void {
        settingsProc.running = true;
    }

    Component.onCompleted: root.refresh()

    // Poll wired device state
    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                const wired = text.trim().split("\n")
                    .map(line => line.split(":"))
                    .find(parts => parts[1] === "ethernet");

                root.available = wired !== undefined;
                root.connected = wired !== undefined && wired[2] === "connected";
                root.interfaceName = wired ? wired[0] : "";
            }
        }
    }

    Process {
        id: settingsProc
        command: ["nm-connection-editor"]
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
