pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Notification history panel open/close state
Singleton {
    id: root

    property bool open: false

    function toggle(): void {
        root.open = !root.open;
    }

    // IPC handler
    IpcHandler {
        target: "notifPanel"

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
