pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Dashboard overlay open/close state (mirrors CheatsheetState.qml)
Singleton {
    id: root

    property bool open: false

    function toggle(): void {
        root.open = !root.open;
    }

    // IPC handler
    IpcHandler {
        target: "dashboard"

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
