import QtQuick
import "../../services"

// Updates page. Live against services/Updates.qml. The notification rows at
// the bottom are still mock — nothing in the shell surfaces update counts yet
ScrollPage {
    id: root

    title: "Updates"

    // Minutes into "6 h", "45 min", "2 h 30 min" — the interval reaches a day,
    // where a bare minute count stops being readable
    function formatInterval(mins: int): string {
        const h = Math.floor(mins / 60);
        const m = mins % 60;
        if (h === 0)
            return `${m} min`;
        if (m === 0)
            return `${h} h`;
        return `${h} h ${m} min`;
    }

    SectionLabel {
        text: "Checking"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Check automatically"
            subtext: "Once on login, then on the interval below"

            ToggleSwitch {
                checked: Config.updates.autoCheck
                onToggled: v => Config.updates.autoCheck = v
            }
        }

        SettingRow {
            live: true
            label: "Check every"

            NumberControl {
                value: Config.updates.intervalMinutes
                from: 15
                to: 1440
                stepSize: 15
                // Wider than the default: "23 h 45 min" is the longest readout
                labelWidth: 104
                displayText: root.formatInterval(Config.updates.intervalMinutes)
                onMoved: v => Config.updates.intervalMinutes = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Last checked"

            ValueLabel {
                text: Updates.lastCheckedLabel
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Check now"

            SelectPill {
                enabled: !Updates.checking
                opacity: enabled ? 1 : 0.5
                value: Updates.checking ? "Checking…" : "Refresh"
                icon: "refresh"
                onClicked: Updates.refresh()
            }
        }
    }

    SectionLabel {
        text: "Sources"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Official repositories"
            subtext: "checkupdates"

            ValueLabel {
                text: Updates.repoCount === 0 ? "Up to date" : `${Updates.repoCount} pending`
            }
        }

        SettingRow {
            live: true
            label: "AUR"
            subtext: "Helper used to query for updates"

            SelectPill {
                options: [{ value: "yay", label: "yay" }, { value: "paru", label: "paru" }]
                current: Config.updates.aurHelper
                onSelected: v => Config.updates.aurHelper = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "AUR packages"

            ValueLabel {
                text: Updates.aurCount === 0 ? "Up to date" : `${Updates.aurCount} pending`
            }
        }
    }

    SectionLabel {
        text: Updates.total === 0 ? "Pending" : `Pending · ${Updates.total}`
    }

    // The actual packages. Nothing here upgrades anything — that belongs in a
    // terminal where the output and any prompts are visible
    SettingGroup {
        Repeater {
            model: Updates.repoUpdates.concat(Updates.aurUpdates)

            SettingRow {
                required property int index
                required property var modelData

                live: true
                first: index === 0
                last: index === Updates.total - 1
                label: modelData.name
                subtext: modelData.from && modelData.to ? `${modelData.from} → ${modelData.to}` : ""
            }
        }

        SettingRow {
            visible: Updates.total === 0
            first: true
            last: true
            live: true
            label: Updates.checking ? "Checking…" : "Everything is up to date"
        }
    }

    SectionLabel {
        text: "Notifications"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Notify when updates land"

            ToggleSwitch {
                checked: Config.updates.notify
                onToggled: v => Config.updates.notify = v
            }
        }

        SettingRow {
            live: true
            label: "Show count in the bar"

            ToggleSwitch {
                checked: Config.updates.showInBar
                onToggled: v => Config.updates.showInBar = v
            }
        }

        SettingRow {
            last: true
            label: "Terminal used for upgrades"

            SelectPill {
                value: "kitty"
            }
        }
    }
}
