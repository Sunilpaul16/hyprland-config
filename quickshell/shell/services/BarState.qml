pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Bar visibility state
Singleton {
    id: root

    property bool open: true

    function toggle(): void {
        root.open = !root.open;
    }

    // IPC handler
    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.open = !root.open;
        }

        function open(): void {
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }
    }
}
