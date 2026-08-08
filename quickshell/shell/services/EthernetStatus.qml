pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wired link state
Singleton {
    id: root

    property bool available: false
    property bool connected: false
    property string interfaceName: ""

    // Refcounted polling
    property int refCount: 0

    function ref(): void {
        root.refCount++;
        root.refresh();
    }

    function unref(): void {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    function refresh(): void {
        statusProc.running = true;
    }

    // Open connection editor
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
        interval: Config.polling.networkStatus
        running: root.refCount > 0
        repeat: true
        onTriggered: root.refresh()
    }
}
