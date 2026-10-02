pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Event-driven laptop battery state. Percentages are exposed as 0..100.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: !!device && device.ready && device.isPresent && device.isLaptopBattery
    readonly property bool ready: available && Number.isFinite(device.percentage)
    readonly property real percentage: ready ? Math.max(0, Math.min(100, device.percentage * 100)) : 0
    readonly property string percentageText: ready ? Math.round(percentage) + "%" : "—"
    readonly property bool onBattery: ready && UPower.onBattery
    readonly property bool pluggedIn: ready && !UPower.onBattery
    readonly property bool charging: ready && device.state === UPowerDeviceState.Charging
    readonly property bool discharging: ready && device.state === UPowerDeviceState.Discharging
    readonly property bool fullyCharged: ready && device.state === UPowerDeviceState.FullyCharged
    readonly property bool pendingCharge: ready && device.state === UPowerDeviceState.PendingCharge
    readonly property bool pendingDischarge: ready && device.state === UPowerDeviceState.PendingDischarge
    readonly property bool low: onBattery && percentage <= 20
    readonly property string stateLabel: {
        if (!ready) return "Battery unavailable";
        if (charging) return "Charging";
        if (fullyCharged) return "Fully charged";
        if (pendingCharge) return "Waiting to charge";
        if (pendingDischarge) return "Waiting to discharge";
        if (discharging) return "Discharging";
        return onBattery ? "On battery" : "Connected to power";
    }
    readonly property string icon: {
        if (charging) return "battery_charging_full";
        if (!ready) return "battery_unknown";
        if (percentage <= 5) return "battery_alert";
        if (percentage <= 15) return "battery_0_bar";
        if (percentage <= 30) return "battery_1_bar";
        if (percentage <= 45) return "battery_2_bar";
        if (percentage <= 60) return "battery_3_bar";
        if (percentage <= 75) return "battery_4_bar";
        if (percentage <= 90) return "battery_5_bar";
        return "battery_full";
    }

    property bool monitoring: false
    property var warnedLevels: []
    readonly property var warningLevels: [
        { level: 5, title: "Critical battery", critical: true },
        { level: 10, title: "Very low battery", critical: false },
        { level: 20, title: "Low battery", critical: false }
    ]

    function start(): void {
        root.monitoring = true;
        root.queueCheck();
    }
    function queueCheck(): void {
        if (root.monitoring)
            checkTimer.restart();
    }
    function checkWarnings(): void {
        if (!root.monitoring || !root.ready)
            return;
        const p = root.percentage;
        if (!root.onBattery) {
            // Five percentage points of charge above each threshold re-arms it.
            root.warnedLevels = root.warnedLevels.filter(level => p < level + 5);
            return;
        }
        const crossed = root.warningLevels.filter(w => p <= w.level && !root.warnedLevels.includes(w.level));
        if (crossed.length === 0)
            return;
        // A large drop or startup below several levels emits only the most urgent.
        root.warnedLevels = [...root.warnedLevels, ...crossed.map(w => w.level)];
        const warning = crossed[0];
        Notifs.batteryWarning(warning.title, root.percentageText + " remaining. Connect your charger.", warning.critical);
    }

    onReadyChanged: queueCheck()
    onPercentageChanged: queueCheck()
    onOnBatteryChanged: queueCheck()

    // Coalesce UPower signal updates; this timer never polls or repeats.
    Timer {
        id: checkTimer
        interval: 0
        repeat: false
        onTriggered: root.checkWarnings()
    }
}
