pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light (hyprsunset) state singleton
Singleton {
    id: root

    readonly property int temperature: 4000

    property bool enabled: false

    function toggle(): void {
        root.enabled = !root.enabled;
        applyProc.command = ["bash", "-c", `pidof hyprsunset >/dev/null || { setsid -f hyprsunset >/dev/null 2>&1; sleep 0.5; }; hyprctl hyprsunset ${root.enabled ? `temperature ${root.temperature}` : "identity"}`];
        applyProc.running = true;
    }

    // Apply process (starts hyprsunset on demand, then sets/clears the filter)
    Process {
        id: applyProc
    }

    // IPC handler
    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.toggle();
        }
    }
}
