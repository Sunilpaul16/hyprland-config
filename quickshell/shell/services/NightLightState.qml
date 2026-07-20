pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light (hyprsunset) state singleton
Singleton {
    id: root

    readonly property int temperature: 5200

    // Restored across a shell-only restart (not a fresh Hyprland login —
    // see Persistent.isNewHyprlandInstance), so the toggle doesn't desync
    // from the hyprsunset process, which keeps running across restarts
    property bool enabled: !Persistent.isNewHyprlandInstance && Persistent.nightLightEnabled
    onEnabledChanged: Persistent.nightLightEnabled = root.enabled

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
