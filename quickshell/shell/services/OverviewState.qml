pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Workspace overview open/close state (mirrors CheatsheetState.qml)
Singleton {
    id: root

    property bool open: false
    // Monitor this panel is pinned to while open
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
