pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Session screen state
Singleton {
    id: root

    property bool open: false
    // Pinned monitor
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

    // Auto-close grace
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

        // Lock only
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
