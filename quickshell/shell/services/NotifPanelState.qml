pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Notification history panel open/close state, plus where to anchor it
// (scene coords of NotifButton's bottom-right corner, captured on open —
// same technique as TrayMenuState.anchorX/anchorY)
Singleton {
    id: root

    property bool open: false
    property real anchorX: 0
    property real anchorY: 0

    function showAt(x: real, y: real): void {
        root.anchorX = x;
        root.anchorY = y;
        root.open = true;
    }

    function toggle(x: real, y: real): void {
        if (root.open)
            root.open = false;
        else
            root.showAt(x, y);
    }

    // IPC handler
    IpcHandler {
        target: "notifPanel"

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
