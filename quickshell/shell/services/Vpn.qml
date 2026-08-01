pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// NordVPN state, via its CLI. There is no NetworkManager VPN profile to bind
// to here — nordvpn manages its own tunnel — so this shells out and parses
Singleton {
    id: root

    readonly property string cli: "nordvpn"

    property bool available: false
    property bool connected: false
    property string server: ""
    property string country: ""
    property string ip: ""
    // Set while a connect/disconnect is in flight; both take seconds
    property bool busy: false

    readonly property string statusLabel: {
        if (!root.available)
            return "Not available";
        if (root.busy)
            return "Working…";
        if (!root.connected)
            return "Disconnected";
        return root.country ? `${root.server} · ${root.country}` : root.server;
    }

    // Polled only while something is watching, same refcount shape as
    // SystemUsage/NetworkUsage — nothing else in the shell reads this
    property int refCount: 0

    function ref(): void {
        root.refCount++;
        root.refresh();
    }

    function unref(): void {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function connect(): void {
        if (root.busy)
            return;
        root.busy = true;
        connectProc.running = true;
    }

    function disconnect(): void {
        if (root.busy)
            return;
        root.busy = true;
        disconnectProc.running = true;
    }

    function toggle(): void {
        if (root.connected)
            root.disconnect();
        else
            root.connect();
    }

    function field(text: string, key: string): string {
        const match = new RegExp(`^\\s*${key}:\\s*(.+)$`, "m").exec(text);
        return match ? match[1].trim() : "";
    }

    Process {
        id: statusProc
        command: [root.cli, "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                // A missing/unauthenticated CLI prints something other than
                // "Status:", so treat the field's absence as unavailable
                const status = root.field(text, "Status");
                root.available = status.length > 0;
                root.connected = status.toLowerCase() === "connected";
                root.server = root.field(text, "Hostname") || root.field(text, "Server");
                root.country = root.field(text, "Country");
                root.ip = root.field(text, "IP");
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                root.available = false;
        }
    }

    Process {
        id: connectProc
        command: [root.cli, "connect"]
        onExited: {
            root.busy = false;
            root.refresh();
        }
    }

    Process {
        id: disconnectProc
        command: [root.cli, "disconnect"]
        onExited: {
            root.busy = false;
            root.refresh();
        }
    }

    Timer {
        interval: Config.polling.networkStatus
        running: root.refCount > 0
        repeat: true
        onTriggered: root.refresh()
    }
}
