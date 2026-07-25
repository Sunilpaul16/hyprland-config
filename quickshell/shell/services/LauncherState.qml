pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Launcher open/close state
Singleton {
    id: root

    property bool open: false
    property string pendingText: ""
    // Monitor this panel is pinned to while open
    property string ownerScreen: ""

    onOpenChanged: if (root.open) ScreenOwner.claim(root)

    // Open in each mode. Open on another monitor means move here, which is
    // done as a close/reopen so Content re-syncs its text and keyboard focus
    function openMode(text: string): void {
        const elsewhere = root.open && root.ownerScreen !== ScreenOwner.focusedName;
        if (root.open && !elsewhere) {
            root.open = false;
            return;
        }
        if (elsewhere)
            root.open = false;
        ScreenOwner.claim(root);
        root.pendingText = text;
        root.open = true;
    }

    function openApps(): void {
        root.openMode("");
    }

    function openWallpaper(): void {
        root.openMode(">wallpaper ");
    }

    function openClip(): void {
        root.openMode(">clip ");
    }

    // IPC handler
    IpcHandler {
        target: "launcher"

        function openApps(): void {
            root.openApps();
        }

        function openWallpaper(): void {
            root.openWallpaper();
        }

        function openClip(): void {
            root.openClip();
        }

        function close(): void {
            root.open = false;
        }
    }
}
