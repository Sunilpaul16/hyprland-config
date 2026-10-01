pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// GPU usage (nvidia-smi)
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
    property bool _backendAvailable: false
    property string _name: ""
    property real _percentage: 0
    property real _temperature: 0

    function parseNvidiaSmi(text: string): void {
        // Use one complete record. Multi-GPU output contains one CSV row per GPU.
        const firstRow = (text || "").split("\n").map(line => line.trim()).find(line => line.length > 0) ?? "";
        const parts = firstRow.split(",");
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

    // Check once; unsupported machines never start the polling timer.
    Process {
        running: true
        command: ["sh", "-c", `
            command -v nvidia-smi >/dev/null 2>&1 || exit 1
            for device in /sys/bus/pci/devices/*; do
                IFS= read -r vendor < "$device/vendor" || continue
                [ "$vendor" = "0x10de" ] || continue
                IFS= read -r class < "$device/class" || continue
                case "$class" in
                    0x03*) exec nvidia-smi -L >/dev/null 2>&1 ;;
                esac
            done
            exit 1
        `]
        onExited: exitCode => root._backendAvailable = exitCode === 0
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
        interval: Config.polling.gpu
        running: root._backendAvailable && root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: nvidiaProc.running = true
    }
}
