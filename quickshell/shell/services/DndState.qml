pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Do Not Disturb state: suppresses notification popups, history unaffected
Singleton {
    id: root

    property bool enabled: !Persistent.isNewHyprlandInstance && Persistent.dndEnabled
    onEnabledChanged: Persistent.dndEnabled = root.enabled

    function toggle(): void {
        root.enabled = !root.enabled;
        Notifs.toast(root.enabled ? "Do not disturb on" : "Do not disturb off", root.enabled ? "Notification popups are hidden" : "Notification popups are back", root.enabled ? "do_not_disturb_on" : "do_not_disturb_off");
    }

    // IPC handler
    IpcHandler {
        target: "dnd"

        function toggle(): void {
            root.toggle();
        }

        // Routed through toggle() so the IPC path toasts too, matching IdleInhibitState
        function enable(): void {
            if (!root.enabled)
                root.toggle();
        }

        function disable(): void {
            if (root.enabled)
                root.toggle();
        }
    }
}
