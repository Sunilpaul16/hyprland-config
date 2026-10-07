import QtQuick
import Quickshell.Services.UPower
import "../../services"
import "../../components"

// Idle and power page
ScrollPage {
    id: root

    title: "Idle & power"

    readonly property var powerModeOptions: {
        const modes = [
            { value: "power-saver", label: "Power saver", profile: PowerProfile.PowerSaver },
            { value: "balanced", label: "Balanced", profile: PowerProfile.Balanced }
        ];
        if (PowerProfiles.hasPerformanceProfile)
            modes.push({ value: "performance", label: "Performance", profile: PowerProfile.Performance });
        return modes;
    }
    readonly property string currentPowerMode: root.powerModeOptions.find(
        mode => mode.profile === PowerProfiles.profile)?.value ?? "";
    readonly property string powerModeDescription: {
        let description;
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            description = "Reduce power use for longer battery life";
            break;
        case PowerProfile.Performance:
            description = "Prioritise speed with higher power use and fan noise";
            break;
        default:
            description = "Balance performance and battery life";
        }
        if (PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature)
            description += ". Performance is limited by high temperature";
        else if (PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected)
            description += ". Performance is limited while the laptop is on your lap";
        return description;
    }

    function setPowerMode(value: string): void {
        const mode = root.powerModeOptions.find(option => option.value === value);
        if (mode)
            PowerProfiles.profile = mode.profile;
    }

    SectionLabel {
        text: "Power mode"
    }

    SettingGroup {
        SettingRow {
            first: true
            last: true
            live: true
            label: "Power mode"
            subtext: root.powerModeDescription

            SelectMenu {
                objectName: "powerModeSelector"
                options: root.powerModeOptions
                current: root.currentPowerMode
                onSelected: value => root.setPowerMode(value)
            }
        }
    }

    // Format timeout
    function formatTimeout(mins: int): string {
        if (mins === 0)
            return "Never";
        const h = Math.floor(mins / 60);
        const m = mins % 60;
        if (h === 0)
            return `${m} min`;
        if (m === 0)
            return `${h} h`;
        return `${h} h ${m} min`;
    }

    SectionLabel {
        text: "Idle timeouts"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Lock screen after"
            subtext: "Drag to zero for never"

            NumberControl {
                value: Config.idle.lockTimeout / 60
                from: 0
                to: 120
                stepSize: 5
                labelWidth: 104
                displayText: root.formatTimeout(Math.round(Config.idle.lockTimeout / 60))
                onMoved: v => Config.idle.lockTimeout = Math.round(v) * 60
            }
        }

        SettingRow {
            live: true
            label: "Turn off displays after"

            NumberControl {
                value: Config.idle.dpmsTimeout / 60
                from: 0
                to: 180
                stepSize: 5
                labelWidth: 104
                displayText: root.formatTimeout(Math.round(Config.idle.dpmsTimeout / 60))
                onMoved: v => Config.idle.dpmsTimeout = Math.round(v) * 60
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Suspend after"

            NumberControl {
                value: Config.idle.suspendTimeout / 60
                from: 0
                to: 240
                stepSize: 15
                labelWidth: 104
                displayText: root.formatTimeout(Math.round(Config.idle.suspendTimeout / 60))
                onMoved: v => Config.idle.suspendTimeout = Math.round(v) * 60
            }
        }
    }

    SectionLabel {
        text: "Exceptions"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Stay awake while media plays"
            subtext: "Covers players that don't assert the Wayland inhibitor themselves"

            ToggleSwitch {
                checked: Config.idle.inhibitWhenAudio
                onToggled: v => Config.idle.inhibitWhenAudio = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Keep awake"
            subtext: "Prevent automatic locking, display blanking and suspension"

            ToggleSwitch {
                checked: IdleInhibitState.enabled
                onToggled: v => IdleInhibitState.setEnabled(v)
            }
        }
    }
}
