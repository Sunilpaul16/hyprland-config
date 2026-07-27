pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Settings panel open/close + current-page state
Singleton {
    id: root

    property bool open: false
    // Monitor this panel is pinned to while open
    property string ownerScreen: ""
    // Index into SettingsPanel's pageModel
    property int currentPageIdx: 0

    onOpenChanged: {
        if (!root.open)
            return;
        ScreenOwner.claim(root);
        // Settings is a big centred overlay that covers the sidebar; neither
        // dismisses the other through GlobalFocusGrab, so close it explicitly
        SidebarRightState.open = false;
    }

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    // IPC handler
    IpcHandler {
        target: "settings"

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

        // Page switching without a click — the panel clamps out-of-range values
        function page(idx: int): void {
            root.currentPageIdx = idx;
        }
    }
}
