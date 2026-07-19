pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU + memory usage polling (FileView+Timer pattern, mirrors NetworkUsage.qml)
Singleton {
    id: root

    property int refCount: 0

    function ref(): void {
        root.refCount++;
    }

    function unref(): void {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    // CPU
    readonly property string cpuName: _cpuName
    readonly property real cpuPercentage: _cpuPercentage
    readonly property real cpuTemperature: _cpuTemperature

    // Memory (KiB)
    readonly property real memoryUsedKib: _memoryUsedKib
    readonly property real memoryTotalKib: _memoryTotalKib
    readonly property real memoryPercentage: memoryTotalKib > 0 ? memoryUsedKib / memoryTotalKib : 0

    property string _cpuName: ""
    property real _cpuPercentage: 0
    property real _cpuTemperature: 0
    property real _memoryUsedKib: 0
    property real _memoryTotalKib: 0

    // Previous /proc/stat tick totals, for the idle/total delta ratio
    property real _prevTotal: 0
    property real _prevIdle: 0
    property bool _cpuInitialized: false

    function cleanCpuName(name: string): string {
        return name.replace(/\(R\)|\(TM\)|CPU|\d+(?:th|nd|rd|st) Gen |Core |Processor/gi, "").replace(/\s+/g, " ").trim();
    }

    function parseStat(content: string): void {
        if (!content)
            return;

        const line = content.split("\n")[0];
        const match = line.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (!match)
            return;

        let total = 0;
        let idle = 0;
        for (let i = 1; i <= 7; i++) {
            const v = parseInt(match[i], 10);
            total += v;
            if (i === 4 || i === 5) // idle + iowait
                idle += v;
        }

        if (root._cpuInitialized) {
            const totalDiff = total - root._prevTotal;
            const idleDiff = idle - root._prevIdle;
            if (totalDiff > 0)
                root._cpuPercentage = Math.max(0, Math.min(1, 1 - idleDiff / totalDiff));
        } else {
            root._cpuInitialized = true;
        }

        root._prevTotal = total;
        root._prevIdle = idle;
    }

    // Mirrors caelestia's cpuPackageTemp() label matching (sensorslib.cpp):
    // scan every sensors chip/feature, primary = "Package id N" (Intel) or
    // "Tdie" (AMD), fallback = "Tctl" (AMD, when Tdie isn't exposed).
    function parseSensorsJson(jsonText: string): void {
        if (!jsonText)
            return;

        let data;
        try {
            data = JSON.parse(jsonText);
        } catch (e) {
            return;
        }

        let primary = null;
        let fallback = null;
        for (const chipName in data) {
            const chip = data[chipName];
            for (const featureLabel in chip) {
                const feature = chip[featureLabel];
                if (typeof feature !== "object")
                    continue; // skip the "Adapter" string field

                let inputVal;
                for (const key in feature) {
                    if (key.startsWith("temp") && key.endsWith("_input")) {
                        inputVal = feature[key];
                        break;
                    }
                }
                if (inputVal === undefined)
                    continue;

                if (featureLabel.startsWith("Package id ") || featureLabel === "Tdie")
                    primary = inputVal;
                else if (featureLabel === "Tctl")
                    fallback = inputVal;
            }
        }

        if (primary !== null)
            root._cpuTemperature = primary;
        else if (fallback !== null)
            root._cpuTemperature = fallback;
    }

    function parseMemInfo(content: string): void {
        if (!content)
            return;

        const totalMatch = content.match(/MemTotal:\s*(\d+)/);
        const availMatch = content.match(/MemAvailable:\s*(\d+)/);
        if (!totalMatch || !availMatch)
            return;

        const totalKib = parseInt(totalMatch[1], 10);
        const availKib = parseInt(availMatch[1], 10);
        root._memoryTotalKib = totalKib;
        root._memoryUsedKib = Math.max(0, totalKib - availKib);
    }

    // CPU name — read once, not polled
    FileView {
        id: cpuInfoFile

        path: "/proc/cpuinfo"
        onLoaded: {
            const content = text();
            const match = content.match(/model name\s*:\s*(.+)/);
            if (match)
                root._cpuName = root.cleanCpuName(match[1]);
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
    }

    FileView {
        id: memInfoFile
        path: "/proc/meminfo"
    }

    // CPU package temperature — same 1s cycle as CPU%/memory, not a separate
    // timer, since this is the same "how's the system doing right now" tick
    Process {
        id: sensorsProc
        command: ["sensors", "-j"]
        stdout: StdioCollector { id: sensorsStdout }
        onExited: exitCode => {
            if (exitCode === 0)
                root.parseSensorsJson(sensorsStdout.text);
        }
    }

    Timer {
        interval: 1000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memInfoFile.reload();
            root.parseStat(statFile.text());
            root.parseMemInfo(memInfoFile.text());
            sensorsProc.running = true;
        }
    }
}
