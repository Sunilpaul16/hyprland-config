pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias enabled: props.enabled
    property bool available: false
    readonly property bool busy: apply.running

    function refresh(): void {
        if (!status.running)
            status.running = true;
    }

    function toggle(): void {
        if (available && !busy) {
            apply.requestedEnabled = !enabled;
            apply.command = enabled ? ["hyprctl", "hyprsunset", "identity"] : ["hyprctl", "hyprsunset", "temperature", "5200"];
            apply.running = true;
        }
    }

    PersistentProperties {
        id: props
        reloadableId: "nightLight"
        property bool enabled: false
        property string lastProfile: ""
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: status
        command: ["hyprctl", "hyprsunset", "profile"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.includes("Identity:");
                // Profile reports the schedule, not current manual overrides.
                // Only a schedule boundary should supersede the manual choice.
                if (root.available && text !== props.lastProfile) {
                    props.lastProfile = text;
                    props.enabled = text.includes("Identity: false");
                }
            }
        }
    }

    Process {
        id: apply
        property bool requestedEnabled: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                props.enabled = requestedEnabled;
            root.refresh();
        }
    }

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.toggle(); }
        function isEnabled(): bool { return root.enabled; }
    }
}
