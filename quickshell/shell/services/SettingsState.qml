pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Settings panel state
Singleton {
    id: root

    property bool open: false
    // Pinned monitor
    property string ownerScreen: ""
    // Page index
    property int currentPageIdx: 0
    // Sub-page key
    property string subPage: ""
    // Deep-link page key
    property string pendingPage: ""

    // Reset sub-page
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
        // Close sidebar
        if (Config.sidebar.closeOnSettings)
            SidebarRightState.open = false;
    }

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    // Open page by key
    function openPage(key: string): void {
        root.pendingPage = key;
        ScreenOwner.claim(root);
        root.open = true;
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

        // Page switching
        function page(idx: int): void {
            root.currentPageIdx = idx;
        }
    }
}
