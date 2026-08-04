pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// NordVPN state
Singleton {
    id: root

    readonly property string cli: "nordvpn"

    property bool available: false
    property bool connected: false
    property string server: ""
    property string country: ""
    property string ip: ""
    // In flight
    property bool busy: false
    property string lastActionFailed: "" // "" | "connect" | "disconnect"
    property bool _exited: false

    readonly property string statusLabel: {
        if (!root.available)
            return "Not available";
        if (root.busy)
            return "Working…";
        if (root.lastActionFailed === "connect")
            return "Couldn't connect";
        if (root.lastActionFailed === "disconnect")
            return "Couldn't disconnect";
        if (!root.connected)
            return "Disconnected";
        return root.country ? `${root.server} · ${root.country}` : root.server;
    }

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
        if (!statusProc.running)
            statusProc.running = true;
    }

    function connect(): void {
        if (root.busy)
            return;
        root.busy = true;
        root.lastActionFailed = "";
        root._exited = false;
        connectProc.running = true;
    }

    function disconnect(): void {
        if (root.busy)
            return;
        root.busy = true;
        root.lastActionFailed = "";
        root._exited = false;
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
                // CLI unavailable
                const status = root.field(text, "Status");
                root.available = status.length > 0;
                root.connected = status.toLowerCase() === "connected";
                root.server = root.field(text, "Hostname") || root.field(text, "Server");
                root.country = root.field(text, "Country");
                root.ip = root.field(text, "IP");
            }
        }

        // Exited this run
        property bool sawExit: false

        onExited: exitCode => {
            statusProc.sawExit = true;
            if (exitCode !== 0)
                root.available = false;
        }

        // Covers failure to start
        onRunningChanged: {
            if (statusProc.running)
                statusProc.sawExit = false;
            else if (!statusProc.sawExit)
                root.available = false;
        }
    }

    Process {
        id: connectProc
        command: [root.cli, "connect"]

        onExited: exitCode => {
            root._exited = true;
            if (exitCode !== 0)
                root.lastActionFailed = "connect";
            root.refresh();
        }

        // Also fires on failure to start
        onRunningChanged: {
            if (!connectProc.running) {
                if (!root._exited)
                    root.lastActionFailed = "connect";
                root.busy = false;
            }
        }
    }

    Process {
        id: disconnectProc
        command: [root.cli, "disconnect"]

        onExited: exitCode => {
            root._exited = true;
            if (exitCode !== 0)
                root.lastActionFailed = "disconnect";
            root.refresh();
        }

        // Also fires on failure to start
        onRunningChanged: {
            if (!disconnectProc.running) {
                if (!root._exited)
                    root.lastActionFailed = "disconnect";
                root.busy = false;
            }
        }
    }

    Timer {
        interval: Config.polling.networkStatus
        running: root.refCount > 0
        repeat: true
        onTriggered: root.refresh()
    }
}
