pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Per-wallpaper framing
Singleton {
    id: root

    readonly property real defaultOffset: 0.5
    property var offsets: ({})

    readonly property real current: root.offsetFor(Wallpapers.current)
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    property var sockets: ({})

    function offsetFor(path: string): real {
        if (!path)
            return root.defaultOffset;
        const v = root.offsets[path];
        return (typeof v === "number" && Number.isFinite(v)) ? v : root.defaultOffset;
    }

    function setFor(path: string, value: real): void {
        if (!path)
            return;
        const v = Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : root.defaultOffset;
        const next = Object.assign({}, root.offsets);
        next[path] = v;
        root.offsets = next;
        writeDebounce.restart();
        root.push(v);
    }

    // Flush pending write
    function flush(): void {
        writeDebounce.stop();
        file.setText(JSON.stringify(root.offsets, null, 2));
    }

    // Live mpv push
    function push(value: real): void {
        const payload = JSON.stringify({
            command: ["set_property", "video-align-x", value * 2 - 1]
        }) + "\n";
        for (const s of Object.values(root.sockets)) {
            if (s && s.connected) {
                s.write(payload);
                s.flush();
            }
        }
    }

    function parse(raw: string): void {
        try {
            const parsed = JSON.parse(raw);
            root.offsets = (parsed && typeof parsed === "object") ? parsed : ({});
        } catch (e) {
            root.offsets = ({});
        }
    }

    // State file
    FileView {
        id: file
        path: Directories.wallpaperFramingFile
        watchChanges: true
        printErrors: false
        blockWrites: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }

    // Debounced write
    Timer {
        id: writeDebounce
        interval: 300
        onTriggered: file.setText(JSON.stringify(root.offsets, null, 2))
    }

    // Reconnect backoff
    readonly property int fastRetries: 5
    readonly property int maxInterval: 5000
    property int consecutiveFailures: 0

    function onConnectSuccess(): void {
        root.consecutiveFailures = 0;
        reconnectTimer.interval = 1000;
    }

    function onConnectFailure(): void {
        root.consecutiveFailures++;
        if (root.consecutiveFailures > root.fastRetries) {
            reconnectTimer.interval = Math.min(1000 * Math.pow(2, root.consecutiveFailures - root.fastRetries), root.maxInterval);
        }
    }

    // Socket factory
    Component {
        id: socketComponent
        Socket {
            connected: true
            onConnectedChanged: if (connected)
                root.onConnectSuccess()
            onError: root.onConnectFailure()
        }
    }

    function ensureSockets(): void {
        const names = Quickshell.screens.map(s => s.name);
        for (const name of names) {
            const existing = root.sockets[name];
            if (existing && existing.connected)
                continue;
            if (existing)
                existing.destroy();
            root.sockets[name] = socketComponent.createObject(root, {
                path: `${root.runtimeDir}/mpvpaper-${name}.sock`
            });
        }
        for (const name of Object.keys(root.sockets)) {
            if (!names.includes(name)) {
                root.sockets[name].destroy();
                delete root.sockets[name];
            }
        }
    }

    // Reconnect timer
    Timer {
        id: reconnectTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.ensureSockets()
    }

    IpcHandler {
        target: "framing"

        function get(): string {
            return String(root.current);
        }

        function set(value: string): string {
            const v = parseFloat(value);
            if (isNaN(v))
                return "invalid";
            root.setFor(Wallpapers.current, v);
            return String(root.offsetFor(Wallpapers.current));
        }

        function nudge(delta: string): string {
            const d = parseFloat(delta);
            if (isNaN(d))
                return "invalid";
            root.setFor(Wallpapers.current, root.current + d);
            return String(root.offsetFor(Wallpapers.current));
        }
    }
}
