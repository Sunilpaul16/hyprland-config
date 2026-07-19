pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Do Not Disturb state: suppresses notification popups, history unaffected
Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        root.enabled = !root.enabled;
    }

    // IPC handler
    IpcHandler {
        target: "dnd"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }
    }
}
