pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Session-only focus timer. Restores the two settings it temporarily owns.
Singleton {
    id: root

    property bool enabled: false
    property int remainingSeconds: 0
    property bool previousDnd: false
    property bool previousIdleInhibit: false

    readonly property string remainingLabel: {
        const minutes = Math.floor(root.remainingSeconds / 60);
        const seconds = root.remainingSeconds % 60;
        return `${minutes}:${seconds.toString().padStart(2, "0")}`;
    }

    function start(minutes: int): void {
        if (!root.enabled) {
            root.previousDnd = DndState.enabled;
            root.previousIdleInhibit = IdleInhibitState.enabled;
        }

        root.enabled = true;
        root.remainingSeconds = Math.max(1, minutes) * 60;
        DndState.enabled = true;
        IdleInhibitState.setEnabled(true);
        tick.start();
        Notifs.toast("Focus mode started", `${minutes} minutes · notifications muted`, "center_focus_strong");
    }

    function stop(completed: bool): void {
        if (!root.enabled)
            return;

        tick.stop();
        root.enabled = false;
        root.remainingSeconds = 0;

        // Game mode also owns these switches, so never undo its requirements.
        DndState.enabled = GameModeState.enabled ? true : root.previousDnd;
        IdleInhibitState.setEnabled(GameModeState.enabled ? true : root.previousIdleInhibit);
        Notifs.toast(completed ? "Focus session complete" : "Focus mode stopped",
            completed ? "Time for a break" : "Your previous notification and idle settings were restored",
            completed ? "task_alt" : "center_focus_weak");
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            root.remainingSeconds--;
            if (root.remainingSeconds <= 0)
                root.stop(true);
        }
    }

    IpcHandler {
        target: "focus"

        function start25(): void { root.start(25); }
        function start50(): void { root.start(50); }
        function start90(): void { root.start(90); }
        function stop(): void { root.stop(false); }
        function status(): string {
            return `enabled=${root.enabled} remaining=${root.remainingLabel}`;
        }
    }
}
