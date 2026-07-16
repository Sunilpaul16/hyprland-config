pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Workspace overview open/close state (mirrors CheatsheetState.qml)
Singleton {
    id: root

    property bool open: false

    function toggle(): void {
        root.open = !root.open;
    }

    // IPC handler
    IpcHandler {
        target: "overview"

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
