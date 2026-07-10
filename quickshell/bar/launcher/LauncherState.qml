pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tiny shared on/off switch for the launcher overlay (see Launcher.qml). A
// singleton rather than a per-window property because the IPC call and the
// per-monitor Launcher instances (one per screen, like Bar.qml) all need to
// see the same state.
//
// `pendingText` is how the two mode-specific entry points below tell
// Content.qml what the search field should start with — Content.qml reads it
// once in its onOpenChanged handler (see the Connections block there). The
// mode itself (apps/commands/wallpaper) isn't stored anywhere separately —
// it's derived from the search text's prefix, so seeding the initial text is
// all that's needed to "open directly in wallpaper mode."
Singleton {
    id: root

    property bool open: false
    property string pendingText: ""

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
