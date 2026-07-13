pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Cheatsheet open/close state
Singleton {
    id: root

    property bool open: false

    onOpenChanged: if (root.open) Binds.refresh()

    function toggle(): void {
        root.open = !root.open;
    }

    // IPC handler
    IpcHandler {
        target: "cheatsheet"

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
