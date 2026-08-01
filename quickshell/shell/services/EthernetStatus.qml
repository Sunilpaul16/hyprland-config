pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wired link state via nmcli — Quickshell.Networking's DeviceType enum has only None/Wifi, so no native binding exists for ethernet
Singleton {
    id: root

    property bool available: false
    property bool connected: false
    property string interfaceName: ""

    function refresh(): void {
        statusProc.running = true;
    }

    // Launch NetworkManager's connection editor — the "Edit Connections" target nm-applet opened before it was filtered out (see Tray.qml's hiddenIds)
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
