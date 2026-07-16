pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Keep Awake state. Uses Quickshell's native Wayland idle-inhibit protocol
// (idle-inhibit-unstable-v1, honored directly by Hyprland) rather than
// spawning a systemd-inhibit subprocess -- the inhibitor is tied to this
// invisible surface's lifetime, so a qs restart/crash releases it
// automatically instead of leaving an orphaned lock behind.
Singleton {
    id: root

    property bool enabled: false
    property real activeSince: 0 // Date.now() ms, 0 when inactive

    function toggle(): void {
        root.enabled = !root.enabled;
        root.activeSince = root.enabled ? Date.now() : 0;
    }

    // IPC handler (matches CheatsheetState/OverviewState convention)
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
