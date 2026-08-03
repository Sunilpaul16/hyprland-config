pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light (hyprsunset) state singleton
Singleton {
    id: root

    readonly property int temperature: Config.nightLight.temperature

    // Restored across a shell-only restart, not a fresh login (see Persistent.isNewHyprlandInstance), so the toggle can't desync from the surviving hyprsunset
    property bool enabled: !Persistent.isNewHyprlandInstance && Persistent.nightLightEnabled
    onEnabledChanged: Persistent.nightLightEnabled = root.enabled

    // Set by shell.qml — nothing else references this singleton until the sidebar is first opened, and a schedule that only starts then isn't a schedule
    property bool scheduling: false

    readonly property bool scheduleActive: root.scheduling && Config.ready && Config.nightLight.schedule

    // An overnight window wraps past midnight, which inverts the test
    readonly property bool withinSchedule: {
        const start = Config.nightLight.startHour;
        const end = Config.nightLight.endHour;
        const hour = Time.hours;
        if (start === end)
            return false;
        return start < end ? hour >= start && hour < end : hour >= start || hour < end;
    }

    // Crossing a boundary announces; taking the schedule up does not, since a shell restart inside the window would otherwise toast every time
    onWithinScheduleChanged: root.applySchedule(true)
    onScheduleActiveChanged: root.applySchedule(false)

    function applySchedule(announce: bool): void {
        if (!root.scheduleActive)
            return;
        // Re-applied even when the value already matches: on a fresh login hyprsunset isn't running yet, so the state can be right while the screen isn't
        root.setEnabled(root.withinSchedule, announce && root.enabled !== root.withinSchedule);
    }

    function setEnabled(on: bool, announce: bool): void {
        root.enabled = on;
        applyProc.command = ["bash", "-c", `pidof hyprsunset >/dev/null || { setsid -f hyprsunset >/dev/null 2>&1; sleep 0.5; }; hyprctl hyprsunset ${on ? `temperature ${root.temperature}` : "identity"}`];
        applyProc.running = true;
        if (announce)
            Notifs.toast(on ? "Night light on" : "Night light off", on ? `Screen warmed to ${root.temperature}K` : "Colour temperature restored", on ? "bedtime" : "bedtime_off");
    }

    // A manual flip stands until the next scheduled boundary
    function toggle(): void {
        root.setEnabled(!root.enabled, true);
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

        function status(): string {
            return `enabled=${root.enabled} schedule=${Config.nightLight.schedule} window=${Config.nightLight.startHour}-${Config.nightLight.endHour} within=${root.withinSchedule}`;
        }
    }
}
