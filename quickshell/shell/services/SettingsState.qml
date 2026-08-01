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
    // Key into Content.qml's subPageModel; "" means the page itself is shown. One level deep only
    property string subPage: ""

    // Leaving a page abandons any sub-page it opened
    onCurrentPageIdxChanged: root.subPage = ""

    function openSubPage(key: string): void {
        root.subPage = key;
    }

    function closeSubPage(): void {
        root.subPage = "";
    }

    onOpenChanged: {
        if (!root.open)
            return;
        ScreenOwner.claim(root);
        root.subPage = "";
        // Settings is a big centred overlay that covers the sidebar; neither
        // dismisses the other through GlobalFocusGrab, so close it explicitly
        if (Config.sidebar.closeOnSettings)
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

        function sub(key: string): void {
            root.subPage = key;
        }

        function back(): void {
            root.closeSubPage();
        }

        // Page switching without a click — the panel clamps out-of-range values
        function page(idx: int): void {
            root.currentPageIdx = idx;
        }
    }
}
