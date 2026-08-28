pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Idle-inhibit state
Singleton {
    id: root

    // Restored across restart
    property bool enabled: Persistent.isNewHyprlandInstance ? Config.session.keepAwakeDefault : Persistent.idleInhibitEnabled
    property real activeSince: root.enabled ? Date.now() : 0 // Date.now() ms, 0 when inactive
    onEnabledChanged: Persistent.idleInhibitEnabled = root.enabled

    function setEnabled(value: bool): void {
        if (root.enabled === value)
            return;

        root.enabled = value;
        root.activeSince = root.enabled ? Date.now() : 0;
        Notifs.toast(root.enabled ? "Keep awake on" : "Keep awake off", root.enabled ? "Screen blanking and idle are inhibited" : "Normal idle behaviour restored", root.enabled ? "coffee" : "bedtime");
    }

    function toggle(): void {
        root.setEnabled(!root.enabled);
    }

    // IPC handler
    IpcHandler {
        target: "idleinhibit"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.setEnabled(true);
        }

        function disable(): void {
            root.setEnabled(false);
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
