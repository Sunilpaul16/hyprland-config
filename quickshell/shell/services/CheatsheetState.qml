pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Cheatsheet open/close state
Singleton {
    id: root

    property bool open: false
    // Monitor this panel is pinned to while open
    property string ownerScreen: ""

    onOpenChanged: {
        if (!root.open)
            return;
        ScreenOwner.claim(root);
        Binds.refresh();
    }

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    // IPC handler
    IpcHandler {
        target: "cheatsheet"

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
