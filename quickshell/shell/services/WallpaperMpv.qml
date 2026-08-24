pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// mpvpaper IPC
Singleton {
    id: root

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    property var sockets: ({})

    signal socketConnected(string monitor)

    function send(sock, args): void {
        if (!sock || !sock.connected)
            return;
        sock.write(JSON.stringify({
            command: args
        }) + "\n");
        sock.flush();
    }

    // Broadcast to instances
    function command(args): void {
        for (const s of Object.values(root.sockets))
            root.send(s, args);
    }

    // Target one monitor
    function commandTo(monitor: string, args): void {
        root.send(root.sockets[monitor], args);
    }

    // Emit once, after mapping
    function announce(sock): void {
        if (!sock || sock.announced || !sock.connected)
            return;
        if (root.sockets[sock.monitor] !== sock)
            return;
        sock.announced = true;
        root.socketConnected(sock.monitor);
    }

    // Reconnect backoff
    readonly property int fastRetries: 5
    readonly property int maxInterval: 5000
    property var retryStates: ({})
    readonly property bool allConnected: Quickshell.screens.length > 0
        && Quickshell.screens.every(s => root.sockets[s.name]?.connected ?? false)

    function retryState(monitor: string): var {
        return root.retryStates[monitor] ?? { failures: 0, nextAttempt: 0 };
    }

    function setRetryState(monitor: string, failures: int): void {
        const delay = failures <= root.fastRetries ? 1000
            : Math.min(1000 * Math.pow(2, failures - root.fastRetries), root.maxInterval);
        const next = Object.assign({}, root.retryStates);
        next[monitor] = { failures, nextAttempt: Date.now() + delay };
        root.retryStates = next;
    }

    function onConnectSuccess(monitor: string): void {
        root.setRetryState(monitor, 0);
    }

    function onConnectFailure(monitor: string): void {
        root.setRetryState(monitor, root.retryState(monitor).failures + 1);
    }

    // Socket factory
    Component {
        id: socketComponent
        Socket {
            property string monitor
            property bool announced: false
            connected: true
            onConnectedChanged: {
                if (connected) {
                    root.onConnectSuccess(monitor);
                    root.announce(this);
                }
            }
            onError: root.onConnectFailure(monitor)
        }
    }

    function ensureSockets(): void {
        const names = Quickshell.screens.map(s => s.name);
        const created = [];
        for (const name of names) {
            const existing = root.sockets[name];
            if (existing && existing.connected)
                continue;
            if (Date.now() < root.retryState(name).nextAttempt)
                continue;
            if (existing)
                existing.destroy();
            root.sockets[name] = socketComponent.createObject(root, {
                monitor: name,
                path: `${root.runtimeDir}/mpvpaper-${name}.sock`
            });
            created.push(name);
        }
        for (const name of Object.keys(root.sockets)) {
            if (!names.includes(name)) {
                root.sockets[name].destroy();
                delete root.sockets[name];
                const next = Object.assign({}, root.retryStates);
                delete next[name];
                root.retryStates = next;
            }
        }
        // Catch synchronous connects
        for (const name of created)
            root.announce(root.sockets[name]);
    }

    // Reconnect timer
    Timer {
        id: reconnectTimer
        interval: root.allConnected ? 5000 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.ensureSockets()
    }
}
