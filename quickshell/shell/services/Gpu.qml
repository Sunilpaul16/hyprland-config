pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// GPU usage + temperature polling via nvidia-smi — Nvidia only (this box
// has no AMD/Intel gpu_busy_percent sysfs path, so no fallback path is
// built). Same ref-counted shape as SystemUsage.qml/NetworkUsage.qml.
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
    readonly property string name: _name
    readonly property real percentage: _percentage
    readonly property real temperature: _temperature

    property bool _available: false
    property string _name: ""
    property real _percentage: 0
    property real _temperature: 0

    function parseNvidiaSmi(text: string): void {
        const parts = (text || "").trim().split(",");
        if (parts.length < 3) {
            root._available = false;
            return;
        }

        const usage = parseFloat(parts[1]);
        const temp = parseFloat(parts[2]);
        if (isNaN(usage) || isNaN(temp)) {
            root._available = false;
            return;
        }

        root._available = true;
        root._name = parts[0].trim();
        root._percentage = Math.max(0, Math.min(1, usage / 100));
        root._temperature = temp;
    }

    Process {
        id: nvidiaProc
        command: ["nvidia-smi", "--query-gpu=name,utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
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
