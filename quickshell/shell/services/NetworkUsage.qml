pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Network throughput polling: /proc/net/dev delta-based speed + session
// totals + a capped sample history for sparkline graphs. Same FileView+Timer
// shape as SystemUsage.qml.
//
// NOTE: this file didn't exist in this repo before this session — an
// earlier task assumed it was already here. Built fresh, with a plain
// capped JS array standing in for a C++ CircularBuffer.
Singleton {
    id: root

    property int refCount: 0
    readonly property int historyLength: 30

    function ref(): void {
        root.refCount++;
    }

    function unref(): void {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    // Current speeds in bytes per second
    readonly property real downloadSpeed: _downloadSpeed
    readonly property real uploadSpeed: _uploadSpeed

    // Total bytes transferred since tracking started
    readonly property real downloadTotal: _downloadTotal
    readonly property real uploadTotal: _uploadTotal

    // Sample history for sparkline graphs (oldest first, capped at historyLength)
    readonly property list<real> downloadHistory: _downloadHistory
    readonly property list<real> uploadHistory: _uploadHistory

    property real _downloadSpeed: 0
    property real _uploadSpeed: 0
    property real _downloadTotal: 0
    property real _uploadTotal: 0
    property list<real> _downloadHistory: []
    property list<real> _uploadHistory: []

    property real _prevTimestamp: 0
    property bool _initialized: false
    // Per-interface {rx, tx} baseline, so a vanished NIC just stops contributing instead of reading as a wraparound
    property var _ifaceState: ({})

    function formatBytes(bytes: real): var {
        if (!isFinite(bytes) || bytes < 0)
            return { value: 0, unit: "B/s" };
        if (bytes < 1024)
            return { value: bytes, unit: "B/s" };
        if (bytes < 1024 * 1024)
            return { value: bytes / 1024, unit: "KB/s" };
        if (bytes < 1024 * 1024 * 1024)
            return { value: bytes / (1024 * 1024), unit: "MB/s" };
        return { value: bytes / (1024 * 1024 * 1024), unit: "GB/s" };
    }

    function formatBytesTotal(bytes: real): var {
        if (!isFinite(bytes) || bytes < 0)
            return { value: 0, unit: "B" };
        if (bytes < 1024)
            return { value: bytes, unit: "B" };
        if (bytes < 1024 * 1024)
            return { value: bytes / 1024, unit: "KB" };
        if (bytes < 1024 * 1024 * 1024)
            return { value: bytes / (1024 * 1024), unit: "MB" };
        return { value: bytes / (1024 * 1024 * 1024), unit: "GB" };
    }

    function pushCapped(history: list<real>, value: real): var {
        const next = history.concat([value]);
        if (next.length > root.historyLength)
            next.shift();
        return next;
    }

    function parseNetDev(content: string): void {
        if (!content)
            return;

        const lines = content.split("\n");
        const seen = {};
        let rxDeltaSum = 0;
        let txDeltaSum = 0;

        for (let i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;

            const parts = line.split(/\s+/);
            if (parts.length < 10)
                continue;

            const iface = parts[0].replace(":", "");
            if (iface === "lo")
                continue;

            const rx = parseFloat(parts[1]) || 0;
            const tx = parseFloat(parts[9]) || 0;
            seen[iface] = true;

            // A lower reading means this interface reset, not a real wraparound (~584yr at 1GB/s)
            const prev = root._ifaceState[iface];
            if (prev) {
                if (rx >= prev.rx)
                    rxDeltaSum += rx - prev.rx;
                if (tx >= prev.tx)
                    txDeltaSum += tx - prev.tx;
            }
            root._ifaceState[iface] = { rx: rx, tx: tx };
        }

        // Drop vanished interfaces so a later NIC starts a fresh baseline
        for (const name in root._ifaceState) {
            if (!seen[name])
                delete root._ifaceState[name];
        }

        const now = Date.now();

        if (!root._initialized) {
            root._prevTimestamp = now;
            root._initialized = true;
            return;
        }

        const timeDelta = (now - root._prevTimestamp) / 1000;
        if (timeDelta > 0) {
            root._downloadSpeed = rxDeltaSum / timeDelta;
            root._uploadSpeed = txDeltaSum / timeDelta;

            root._downloadHistory = root.pushCapped(root._downloadHistory, root._downloadSpeed);
            root._uploadHistory = root.pushCapped(root._uploadHistory, root._uploadSpeed);
        }

        root._downloadTotal += rxDeltaSum;
        root._uploadTotal += txDeltaSum;

        root._prevTimestamp = now;
    }

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
    }

    // Per-second sampling tick
    Timer {
        interval: 1000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netDevFile.reload();
            root.parseNetDev(netDevFile.text());
        }
    }
}
