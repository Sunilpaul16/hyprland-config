pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Dashboard open state
Singleton {
    id: root

    property bool open: false
    // Pinned monitor
    property string ownerScreen: ""

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    function show(): void {
        ScreenOwner.claim(root);
        root.open = true;
    }

    // Hover grace timer
    function cancelHoverClose(): void {
        hoverCloseTimer.stop();
    }
    function scheduleHoverClose(): void {
        hoverCloseTimer.restart();
    }

    Timer {
        id: hoverCloseTimer
        interval: 500
        repeat: false
        onTriggered: root.open = false
    }

    // Hover and pinning
    onOpenChanged: {
        if (root.open) {
            ScreenOwner.claim(root);
            ExclusiveHover.claim(root);
        } else {
            ExclusiveHover.release(root);
        }
    }

    // IPC handler
    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }
    }
}
