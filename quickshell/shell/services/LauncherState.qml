pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Launcher open/close state
Singleton {
    id: root

    property bool open: false
    property string pendingText: ""

    // Open in each mode
    function openApps(): void {
        if (root.open) {
            root.open = false;
            return;
        }
        root.pendingText = "";
        root.open = true;
    }

    function openWallpaper(): void {
        if (root.open) {
            root.open = false;
            return;
        }
        root.pendingText = ">wallpaper ";
        root.open = true;
    }

    function openClip(): void {
        if (root.open) {
            root.open = false;
            return;
        }
        root.pendingText = ">clip ";
        root.open = true;
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
