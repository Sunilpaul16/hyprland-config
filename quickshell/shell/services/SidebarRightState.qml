pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Right sidebar open/close state
Singleton {
    id: root

    property bool open: false
    // Monitor this panel is pinned to while open
    property string ownerScreen: ""
    // Quick-toggles edit mode; settings navigates here rather than holding a value
    property bool quickTogglesEditMode: false

    onOpenChanged: {
        if (root.open)
            ScreenOwner.claim(root);
        else
            root.quickTogglesEditMode = false;
    }

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    // IPC handler
    IpcHandler {
        target: "sidebarRight"

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
