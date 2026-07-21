pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen recording process state — shared by the bar's RecordingIndicator and
// the sidebar's ScreenRecorderCard, backed by the same ~/.local/bin/record
// script the record keybinds use (wf-recorder underneath)
Singleton {
    id: root

    readonly property string recordBin: Directories.recordScript

    property bool active: false
    property real startedAt: 0
    property int elapsedSeconds: 0
    property string mode: "full" // "full" | "region" — used for the next recording

    // active only refreshes on the 1s pgrep poll, so a rapid double-toggle
    // could see !active both times and start wf-recorder twice instead of
    // starting then stopping — this closes that window optimistically,
    // cleared unconditionally once the next poll has fresh information
    property bool starting: false

    readonly property string elapsedLabel: StringUtils.friendlyTimeForSeconds(root.elapsedSeconds)

    function cycleMode(): void {
        root.mode = root.mode === "full" ? "region" : "full";
    }

    // Start (using the selected mode) if idle, stop if active
    function toggle(): void {
        if (root.active) {
            root.stop();
        } else if (!root.starting) {
            root.starting = true;
            Quickshell.execDetached([root.recordBin, root.mode]);
        }
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
            root.starting = false;
        }
    }
}
