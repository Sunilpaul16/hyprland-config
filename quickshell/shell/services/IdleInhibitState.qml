pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Idle-inhibit state
Singleton {
    id: root

    property bool enabled: false
    property real activeSince: 0 // Date.now() ms, 0 when inactive

    function toggle(): void {
        root.enabled = !root.enabled;
        root.activeSince = root.enabled ? Date.now() : 0;
    }

    // IPC handler
    IpcHandler {
        target: "idleinhibit"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            if (!root.enabled)
                root.toggle();
        }

        function disable(): void {
            if (root.enabled)
                root.toggle();
        }
    }

    // Wayland idle-inhibit surface
    IdleInhibitor {
        enabled: root.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors { right: true; bottom: true }
            mask: Region { item: null }
        }
    }
}
