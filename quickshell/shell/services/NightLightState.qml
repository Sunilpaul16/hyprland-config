pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light state
Singleton {
    id: root

    readonly property int temperature: Config.nightLight.temperature

    // Restored across restart
    property bool enabled: !Persistent.isNewHyprlandInstance && Persistent.nightLightEnabled
    onEnabledChanged: Persistent.nightLightEnabled = root.enabled

    // Poked by shell.qml
    property bool scheduling: false

    readonly property bool scheduleActive: root.scheduling && Config.ready && Config.nightLight.schedule

    // Overnight window
    readonly property bool withinSchedule: {
        const start = Config.nightLight.startHour;
        const end = Config.nightLight.endHour;
        const hour = Time.hours;
        if (start === end)
            return false;
        return start < end ? hour >= start && hour < end : hour >= start || hour < end;
    }

    // Announce on boundary
    onWithinScheduleChanged: root.applySchedule(true)
    onScheduleActiveChanged: root.applySchedule(false)

    function applySchedule(announce: bool): void {
        if (!root.scheduleActive)
            return;
        // Re-apply always
        root.setEnabled(root.withinSchedule, announce && root.enabled !== root.withinSchedule);
    }

    function setEnabled(on: bool, announce: bool): void {
        root.enabled = on;
        applyProc.command = ["bash", "-c", `pidof hyprsunset >/dev/null || { setsid -f hyprsunset >/dev/null 2>&1; sleep 0.5; }; hyprctl hyprsunset ${on ? `temperature ${root.temperature}` : "identity"}`];
        applyProc.running = true;
        if (announce)
            Notifs.toast(on ? "Night light on" : "Night light off", on ? `Screen warmed to ${root.temperature}K` : "Colour temperature restored", on ? "bedtime" : "bedtime_off");
    }

    // Manual override
    function toggle(): void {
        root.setEnabled(!root.enabled, true);
    }

    // Apply process
    Process {
        id: applyProc
    }

    // IPC handler
    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.toggle();
        }

        function status(): string {
            return `enabled=${root.enabled} schedule=${Config.nightLight.schedule} window=${Config.nightLight.startHour}-${Config.nightLight.endHour} within=${root.withinSchedule}`;
        }
    }
}
