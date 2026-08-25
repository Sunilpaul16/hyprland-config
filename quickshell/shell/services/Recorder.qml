pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen recording state
Singleton {
    id: root

    readonly property string recordBin: Directories.recordScript
    readonly property string stateFile: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-recorder.state"

    property bool active: false
    property real startedAt: 0
    property int elapsedSeconds: 0
    // Session mode
    property string mode: Config.recorder.defaultMode  // "full" | "region"

    // Double-start guard
    property bool starting: false
    // Spawn grace
    property real startRequestedAt: 0

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
            root.startRequestedAt = Date.now();
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
        // Fast while busy
        readonly property bool watching: root.active || root.starting

        interval: watching ? 1000 : 15000
        running: true
        repeat: true
        onTriggered: {
            if (!pollProc.running)
                pollProc.running = true;
            if (root.active)
                root.elapsedSeconds = Math.floor((Date.now() - root.startedAt) / 1000);
        }
    }

    // Poll only the recorder instance launched by this shell.
    Process {
        id: pollProc
        command: ["bash", "-c", "read -r pid started < \"$1\" 2>/dev/null || { echo idle; exit; }; test -r \"/proc/$pid/comm\" && test \"$(cat \"/proc/$pid/comm\")\" = wf-recorder && printf 'rec %s\\n' \"$started\" || echo idle", "recorder-state", root.stateFile]

        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim();
                const fields = state.split(/\s+/);
                const nowActive = fields[0] === "rec";
                if (nowActive && !root.active) {
                    const persistedStart = Number(fields[1]) * 1000;
                    root.startedAt = Number.isFinite(persistedStart) && persistedStart > 0 ? persistedStart : Date.now();
                }
                root.active = nowActive;
                if (!nowActive)
                    root.elapsedSeconds = 0;
                // Hold while selecting or still spawning
                root.starting = !nowActive && (Date.now() - root.startRequestedAt) < 2000;
            }
        }
    }
}
