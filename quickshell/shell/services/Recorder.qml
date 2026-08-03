pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen recording state
Singleton {
    id: root

    readonly property string recordBin: Directories.recordScript

    property bool active: false
    property real startedAt: 0
    property int elapsedSeconds: 0
    // Session mode
    property string mode: Config.recorder.defaultMode  // "full" | "region"

    // Double-start guard
    property bool starting: false

    readonly property string elapsedLabel: StringUtils.friendlyTimeForSeconds(root.elapsedSeconds)

    function cycleMode(): void {
        root.mode = root.mode === "full" ? "region" : "full";
    }

    // Toggle recording
    function toggle(): void {
        if (root.active) {
            root.stop();
        } else if (!root.starting) {
            root.starting = true;
            // Sound is arg 2
            const args = [root.recordBin, root.mode];
            if (Config.recorder.audio)
                args.push("--sound");
            Quickshell.execDetached(args);
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
