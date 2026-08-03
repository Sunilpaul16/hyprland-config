pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Overview open state
Singleton {
    id: root

    property bool open: false
    // Pinned monitor
    property string ownerScreen: ""

    onOpenChanged: if (root.open) ScreenOwner.claim(root)

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    // IPC handler
    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            ScreenOwner.claim(root);
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }
    }
}
