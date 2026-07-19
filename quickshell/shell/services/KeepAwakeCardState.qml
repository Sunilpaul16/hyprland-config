pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Keep Awake card visibility state (sidebar quick toggle)
Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        root.enabled = !root.enabled;
    }

    // IPC handler
    IpcHandler {
        target: "keepawakecard"

        function toggle(): void {
            root.toggle();
        }
    }
}
