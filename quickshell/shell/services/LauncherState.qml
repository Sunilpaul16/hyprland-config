pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Launcher open/close state
Singleton {
    id: root

    property bool open: false
    property string pendingText: ""
    // Pinned monitor
    property string ownerScreen: ""

    onOpenChanged: if (root.open) ScreenOwner.claim(root)

    // Open in mode
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
