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

    // Drawer dismisses itself if left alone — hovering cancels the pending close so it can't vanish mid-reach, same grace idiom as DashboardState
    function cancelAutoClose(): void {
        autoCloseTimer.stop();
    }
    function scheduleAutoClose(): void {
        autoCloseTimer.restart();
    }

    Timer {
        id: autoCloseTimer
        interval: Config.session.autoCloseDuration
        repeat: false
        onTriggered: root.open = false
    }

    // IPC handler
    IpcHandler {
        target: "session"

        function toggle(): void {
            root.toggle();
        }

        // Only lock is callable. Poweroff/reboot/logout stay off the IPC surface deliberately —
        // a socket that can power the machine off is a footgun, and a keybind can run systemctl directly
        function lock(): void {
            Session.lock();
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
