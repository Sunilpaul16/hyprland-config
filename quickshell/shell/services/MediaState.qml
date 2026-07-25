pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Media popup open/close state
Singleton {
    id: root

    property bool open: false
    // Monitor this panel is pinned to while open
    property string ownerScreen: ""
    property real anchorX: 0
    property real anchorY: 0

    function showAt(x: real, y: real): void {
        ScreenOwner.claim(root);
        if (!isNaN(x))
            root.anchorX = x;
        if (!isNaN(y))
            root.anchorY = y;
        root.open = true;
    }

    function toggle(x: real, y: real): void {
        if (root.open)
            root.open = false;
        else
            root.showAt(x, y);
    }

    // Shared hover state — open while the pill or the popup is hovered
    property bool pillHovered: false
    property bool popupHovered: false
    readonly property bool hovering: root.pillHovered || root.popupHovered

    function setPillHovered(state: bool): void {
        root.pillHovered = state;
    }
    function setPopupHovered(state: bool): void {
        root.popupHovered = state;
    }

    onHoveringChanged: {
        if (root.hovering)
            hoverCloseTimer.stop();
        else if (root.open)
            hoverCloseTimer.restart();
    }

    onOpenChanged: {
        hoverCloseTimer.stop();
        if (root.open) {
            ScreenOwner.claim(root);
            ExclusiveHover.claim(root);
        } else {
            ExclusiveHover.release(root);
            // The popup is gone, so its handler can't report the leave itself
            root.popupHovered = false;
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: 500
        repeat: false
        onTriggered: root.open = false
    }

    // IPC handler
    IpcHandler {
        target: "media"

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
