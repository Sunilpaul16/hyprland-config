pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Recorder card
Singleton {
    id: root

    property bool enabled: !Persistent.isNewHyprlandInstance && Persistent.screenRecorderCardEnabled
    onEnabledChanged: Persistent.screenRecorderCardEnabled = root.enabled

    function toggle(): void {
        root.enabled = !root.enabled;
    }

    // IPC handler
    IpcHandler {
        target: "recordercard"

        function toggle(): void {
            root.toggle();
        }
    }
}
