import QtQuick
import "../../services"
import "../../components"

// Idle and power page
ScrollPage {
    id: root

    title: "Idle & power"

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
            live: true
            label: "Keep awake"
            subtext: "The sidebar toggle holds a Wayland inhibitor, which suspends all of the above"

            ValueLabel {
                text: IdleInhibitState.enabled ? "On" : "Off"
            }
        }
    }
}
