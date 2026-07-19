pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen recording process state — shared by the bar's RecordingIndicator and
// the sidebar's ScreenRecorderCard, backed by the same ~/.local/bin/record
// script the record keybinds use (wf-recorder underneath)
Singleton {
    id: root

    readonly property string recordBin: Quickshell.env("HOME") + "/.local/bin/record"

    property bool active: false
    property real startedAt: 0
    property int elapsedSeconds: 0
    property string mode: "full" // "full" | "region" — used for the next recording

    readonly property string elapsedLabel: {
        const m = Math.floor(root.elapsedSeconds / 60);
        const s = root.elapsedSeconds % 60;
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
    }

    function cycleMode(): void {
        root.mode = root.mode === "full" ? "region" : "full";
    }

    // Start (using the selected mode) if idle, stop if active
    function toggle(): void {
        if (root.active)
            root.stop();
        else
            Quickshell.execDetached([root.recordBin, root.mode]);
    }

    function stop(): void {
        Quickshell.execDetached([root.recordBin, "stop"]);
    }

    // Poll + tick
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!pollProc.running)
                pollProc.running = true;
            if (root.active)
                root.elapsedSeconds = Math.floor((Date.now() - root.startedAt) / 1000);
        }
    }

    // Poll for wf-recorder
    Process {
        id: pollProc
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: exitCode => {
            const nowActive = exitCode === 0;
            if (nowActive && !root.active)
                root.startedAt = Date.now();
            root.active = nowActive;
            if (!nowActive)
                root.elapsedSeconds = 0;
        }
    }
}
