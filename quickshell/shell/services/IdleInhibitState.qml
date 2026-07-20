pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Idle-inhibit state
Singleton {
    id: root

    // Restored across a shell-only restart under the same fence as
    // NightLightState. activeSince is never restored verbatim — the prior
    // inhibitor object died with the old process — it's recomputed fresh
    // whenever enabled turns on, including on this initial restore.
    property bool enabled: !Persistent.isNewHyprlandInstance && Persistent.idleInhibitEnabled
    property real activeSince: root.enabled ? Date.now() : 0 // Date.now() ms, 0 when inactive
    onEnabledChanged: Persistent.idleInhibitEnabled = root.enabled

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
