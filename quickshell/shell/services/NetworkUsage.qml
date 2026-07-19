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

    property real _prevRxBytes: 0
    property real _prevTxBytes: 0
    property real _prevTimestamp: 0
    property real _initialRxBytes: 0
    property real _initialTxBytes: 0
    property bool _initialized: false

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
        let rxBytes = 0;
        let txBytes = 0;

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

            rxBytes += parseFloat(parts[1]) || 0;
            txBytes += parseFloat(parts[9]) || 0;
        }

        const now = Date.now();

        if (!root._initialized) {
            root._initialRxBytes = rxBytes;
            root._initialTxBytes = txBytes;
            root._prevRxBytes = rxBytes;
            root._prevTxBytes = txBytes;
            root._prevTimestamp = now;
            root._initialized = true;
            return;
        }

        const timeDelta = (now - root._prevTimestamp) / 1000;
        if (timeDelta > 0) {
            let rxDelta = rxBytes - root._prevRxBytes;
            let txDelta = txBytes - root._prevTxBytes;

            // Counter wraparound (64-bit) — assume it wrapped rather than went backwards
            if (rxDelta < 0)
                rxDelta += Math.pow(2, 64);
            if (txDelta < 0)
                txDelta += Math.pow(2, 64);

            root._downloadSpeed = rxDelta / timeDelta;
            root._uploadSpeed = txDelta / timeDelta;

            if (isFinite(root._downloadSpeed) && root._downloadSpeed >= 0)
                root._downloadHistory = root.pushCapped(root._downloadHistory, root._downloadSpeed);
            if (isFinite(root._uploadSpeed) && root._uploadSpeed >= 0)
                root._uploadHistory = root.pushCapped(root._uploadHistory, root._uploadSpeed);
        }

        let downTotal = rxBytes - root._initialRxBytes;
        let upTotal = txBytes - root._initialTxBytes;
        if (downTotal < 0)
            downTotal += Math.pow(2, 64);
        if (upTotal < 0)
            upTotal += Math.pow(2, 64);

        root._downloadTotal = downTotal;
        root._uploadTotal = upTotal;

        root._prevRxBytes = rxBytes;
        root._prevTxBytes = txBytes;
        root._prevTimestamp = now;
    }

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
    }

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
