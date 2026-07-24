pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Dashboard overlay open/close state (mirrors CheatsheetState.qml)
Singleton {
    id: root

    property bool open: false

    function toggle(): void {
        root.open = !root.open;
    }

    function show(): void {
        root.open = true;
    }

    // Hover-driven open/close: the bar pill's and the panel's HoverHandlers
    // share this grace timer — entering either cancels a pending close,
    // leaving either (re)starts it, so moving the cursor from the pill down
    // into the panel doesn't close the dashboard mid-transit
    function cancelHoverClose(): void {
        hoverCloseTimer.stop();
    }
    function scheduleHoverClose(): void {
        hoverCloseTimer.restart();
    }

    Timer {
        id: hoverCloseTimer
        interval: 150
        repeat: false
        onTriggered: root.open = false
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
