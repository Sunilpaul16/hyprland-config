pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Right sidebar (Notifications + Keep Awake + Screen Recorder + Quick
// Toggles) open/close state. Static-shell pass: no per-card data lives here,
// just the panel's own visibility.
Singleton {
    id: root

    property bool open: false

    function toggle(): void {
        root.open = !root.open;
    }

    // IPC handler
    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }
    }
}
