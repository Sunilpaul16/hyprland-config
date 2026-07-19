pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// GPU usage + temperature polling via nvidia-smi — Nvidia only (confirmed
// 2026-07-19 this box has no AMD/Intel gpu_busy_percent sysfs path, so no
// fallback path is built; see INDEX.md's Dashboard section for the
// investigation). Tier-1 subprocess-shelling substitute for caelestia's
// hybrid nvidia-smi/sysfs C++ Gpu service. Same ref-counted shape as
// SystemUsage.qml/NetworkUsage.qml.
Singleton {
    id: root

    property int refCount: 0

    function ref(): void {
        root.refCount++;
    }

    function unref(): void {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    readonly property bool available: _available
    readonly property real percentage: _percentage
    readonly property real temperature: _temperature

    property bool _available: false
    property real _percentage: 0
    property real _temperature: 0

    function parseNvidiaSmi(text: string): void {
        const parts = (text || "").trim().split(",");
        if (parts.length < 2) {
            root._available = false;
            return;
        }

        const usage = parseFloat(parts[0]);
        const temp = parseFloat(parts[1]);
        if (isNaN(usage) || isNaN(temp)) {
            root._available = false;
            return;
        }

        root._available = true;
        root._percentage = Math.max(0, Math.min(1, usage / 100));
        root._temperature = temp;
    }

    Process {
        id: nvidiaProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector { id: nvidiaStdout }
        onExited: exitCode => {
            if (exitCode === 0)
                root.parseNvidiaSmi(nvidiaStdout.text);
            else
                root._available = false;
        }
    }

    Timer {
        interval: 2000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: nvidiaProc.running = true
    }
}
