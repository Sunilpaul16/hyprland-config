pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Session/power screen open/close state
Singleton {
    id: root

    property bool open: false
    // Monitor this panel is pinned to while open
    property string ownerScreen: ""

    onOpenChanged: {
        if (root.open) {
            ScreenOwner.claim(root);
            root.scheduleAutoClose();
        } else {
            root.cancelAutoClose();
        }
    }

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    // Drawer dismisses itself if left alone. Hovering it cancels the pending
    // close and leaving restarts it, so it can't vanish mid-reach — same grace
    // idiom as DashboardState's hover close
    function cancelAutoClose(): void {
        autoCloseTimer.stop();
    }
    function scheduleAutoClose(): void {
        autoCloseTimer.restart();
    }

    Timer {
        id: autoCloseTimer
        interval: Config.sessionAutoCloseDuration
        repeat: false
        onTriggered: root.open = false
    }

    // IPC handler
    IpcHandler {
        target: "session"

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
