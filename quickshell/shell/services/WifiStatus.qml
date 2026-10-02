pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property bool connected: false
    property string interfaceName: ""
    property string state: ""
    property string ssid: ""
    property int signal: -1
    property string error: ""
    readonly property bool busy: radioAction.running || connectProc.running || disconnectProc.running
    readonly property bool scanning: scanProc.running
    property var networks: []
    property bool pickerOpen: false
    property int refCount: 0

    readonly property string statusLabel: {
        if (!root.available) return "No adapter";
        if (root.busy) return "Working…";
        if (!root.enabled) return "Off";
        if (root.connected) return "Connected";
        if (root.state.startsWith("connecting")) return "Connecting…";
        return "Disconnected";
    }

    function ref(): void {
        root.refCount++;
        root.refresh();
    }

    function unref(): void {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    function refresh(): void {
        if (!statusProc.running) statusProc.running = true;
        if (!radioProc.running) radioProc.running = true;
    }

    function setEnabled(value: bool): void {
        if (root.busy || !root.available) return;
        root.error = "";
        radioAction.command = ["env", "LC_ALL=C", "nmcli", "radio", "wifi", value ? "on" : "off"];
        radioAction.running = true;
    }

    function scan(): void {
        if (!root.enabled || !root.available || scanProc.running) return;
        root.error = "";
        scanProc.command = ["env", "LC_ALL=C", "nmcli", "-t", "-f", "IN-USE,BSSID,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "ifname", root.interfaceName, "--rescan", "yes"];
        scanProc.running = true;
    }

    // nmcli escapes colons and backslashes in terse output.
    function fields(line: string): var {
        const result = [];
        let field = "";
        let escaped = false;
        for (const char of line) {
            if (escaped) { field += char; escaped = false; }
            else if (char === "\\") escaped = true;
            else if (char === ":") { result.push(field); field = ""; }
            else field += char;
        }
        result.push(field);
        return result;
    }

    function connectNetwork(network: var, password: string): void {
        if (root.busy || !root.enabled) return;
        root.error = "";
        connectProc.payload = JSON.stringify({ bssid: network.bssid, interface: root.interfaceName, password: password });
        connectProc.stdinEnabled = true;
        connectProc.running = true;
    }

    function disconnect(): void {
        if (root.busy || !root.connected) return;
        root.error = "";
        disconnectProc.command = ["nmcli", "--wait", "15", "device", "disconnect", root.interfaceName];
        disconnectProc.running = true;
    }

    function openSettings(): void {
        settingsProc.running = true;
    }

    Component.onCompleted: root.refresh()

    Process {
        id: statusProc
        command: ["env", "LC_ALL=C", "nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const devices = text.trim().split("\n").map(line => line.split(":"))
                    .filter(parts => parts[1] === "wifi");
                const device = devices.find(parts => parts[2] === "connected") || devices[0];
                root.available = device !== undefined;
                root.interfaceName = device ? device[0] : "";
                root.state = device ? device[2] : "";
                if (root.pickerOpen && root.enabled && root.networks.length === 0) root.scan();
                root.connected = root.state === "connected";
                if (!root.connected) {
                    root.ssid = "";
                    root.signal = -1;
                }
                if (root.connected && !networkProc.running) {
                    networkProc.command = ["env", "LC_ALL=C", "nmcli", "-t", "--escape", "no", "-f", "IN-USE,SIGNAL,SSID", "device", "wifi", "list", "ifname", root.interfaceName, "--rescan", "no"];
                    networkProc.running = true;
                }
            }
        }
    }

    Process {
        id: radioProc
        command: ["env", "LC_ALL=C", "nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.trim() === "enabled";
                if (!root.enabled) root.networks = [];
                else if (root.pickerOpen && root.available && root.networks.length === 0) root.scan();
            }
        }
    }

    Process {
        id: networkProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.connected) return;
                const active = text.split("\n").find(line => line.startsWith("*:"));
                if (!active) return;
                // SSID is last so colons and backslashes in network names stay intact.
                const separator = active.indexOf(":", 2);
                const strength = Number(active.slice(2, separator));
                root.signal = separator >= 0 && Number.isFinite(strength) ? strength : -1;
                root.ssid = separator >= 0 ? active.slice(separator + 1) : "";
            }
        }
    }

    Process {
        id: radioAction
        onExited: exitCode => {
            if (exitCode !== 0) root.error = "Couldn't change Wi-Fi. Check NetworkManager permissions.";
            root.refresh();
        }
    }

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.enabled) { root.networks = []; return; }
                const unique = new Map();
                for (const line of text.trim().split("\n")) {
                    const f = root.fields(line);
                    if (f.length < 5 || !f[4]) continue;
                    const network = { active: f[0] === "*", bssid: f[1], signal: Number(f[2]), security: f[3], ssid: f[4] };
                    const key = network.ssid + "\n" + network.security;
                    const previous = unique.get(key);
                    if (!previous || network.active || (!previous.active && network.signal > previous.signal)) unique.set(key, network);
                }
                root.networks = Array.from(unique.values()).sort((a, b) => Number(b.active) - Number(a.active) || b.signal - a.signal);
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) root.error = "Couldn't scan for networks. Try again.";
        }
    }

    Process {
        id: connectProc
        property string payload: ""
        command: ["python3", Directories.repoRoot + "/scripts/wifi-connect.py"]
        onStarted: {
            connectProc.write(connectProc.payload);
            connectProc.payload = "";
            connectProc.stdinEnabled = false;
        }
        onExited: exitCode => {
            if (exitCode !== 0) root.error = "Couldn't connect. Check the password or use the connection editor.";
            root.refresh();
            if (root.pickerOpen) root.scan();
        }
    }

    Process {
        id: disconnectProc
        onExited: exitCode => {
            if (exitCode !== 0) root.error = "Couldn't disconnect. Try again.";
            root.refresh();
            if (root.pickerOpen) root.scan();
        }
    }

    Timer {
        interval: 15000
        running: root.pickerOpen && root.enabled && !root.busy
        repeat: true
        onTriggered: root.scan()
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
