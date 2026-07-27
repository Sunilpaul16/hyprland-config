import QtQuick.Layouts
import "../../services"

// Services page. Layout only — the intervals shown are the ones the polling
// singletons already hardcode, surfaced here as if they were configurable
ScrollPage {
    title: "Services"

    SectionLabel {
        text: "Notifications"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Toast duration"
            subtext: "How long a notification popup stays up"

            NumberControl {
                value: Config.notifications.toastDismissDuration
                from: 1000
                to: 15000
                stepSize: 500
                suffix: " ms"
                onMoved: v => Config.notifications.toastDismissDuration = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Do not disturb"
            subtext: "Suppresses popups, still records them"

            ToggleSwitch {
                checked: DndState.enabled
                onToggled: DndState.toggle()
            }
        }

        SettingRow {
            label: "Keep across restarts"
            subtext: "Persisted by services/Notifs.qml"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            last: true
            label: "Popup position"

            SelectPill {
                value: "Top right"
            }
        }
    }

    SectionLabel {
        text: "Polling"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "CPU & memory"
            subtext: "Dashboard rings and the Performance tab"

            NumberControl {
                value: Config.polling.cpu
                from: 500
                to: 10000
                stepSize: 250
                suffix: " ms"
                onMoved: v => Config.polling.cpu = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "GPU"
            subtext: "nvidia-smi query interval"

            NumberControl {
                value: Config.polling.gpu
                from: 1000
                to: 15000
                stepSize: 500
                suffix: " ms"
                onMoved: v => Config.polling.gpu = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Storage"
            subtext: "df and lsblk interval"

            NumberControl {
                value: Config.polling.storage
                from: 2000
                to: 60000
                stepSize: 1000
                suffix: " ms"
                onMoved: v => Config.polling.storage = Math.round(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Uptime"
            subtext: "Re-reads /proc/uptime"

            NumberControl {
                value: Config.polling.uptime
                from: 10000
                to: 300000
                stepSize: 10000
                suffix: " ms"
                onMoved: v => Config.polling.uptime = Math.round(v)
            }
        }
    }

    SectionLabel {
        text: "Weather"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Location"
            subtext: "Geolocated by IP at startup"

            ValueLabel {
                text: Weather.city || "Locating…"
            }
        }

        SettingRow {
            live: true
            label: "Units"

            SelectPill {
                options: [{ value: "celsius", label: "Celsius" }, { value: "fahrenheit", label: "Fahrenheit" }]
                current: Config.weather.units
                onSelected: v => Config.weather.units = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Refresh interval"

            NumberControl {
                value: Config.weather.refreshMinutes
                from: 5
                to: 240
                stepSize: 5
                suffix: " min"
                onMoved: v => Config.weather.refreshMinutes = Math.round(v)
            }
        }
    }

    SectionLabel {
        text: "Screen recorder"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Default mode"
            subtext: "Mode a fresh session starts in"

            SelectPill {
                options: [{ value: "full", label: "Full screen" }, { value: "region", label: "Region" }]
                current: Config.recorder.defaultMode
                onSelected: v => Config.recorder.defaultMode = v
            }
        }

        SettingRow {
            live: true
            label: "Save to"

            ValueLabel {
                text: Directories.videosDir
            }
        }

        SettingRow {
            last: true
            label: "Record audio"

            ToggleSwitch {
                checked: false
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "Idle & night light"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Night light temperature"
            subtext: "Applied by hyprsunset when enabled"

            NumberControl {
                value: Config.nightLight.temperature
                from: 2500
                to: 6500
                stepSize: 100
                suffix: " K"
                onMoved: v => Config.nightLight.temperature = Math.round(v)
            }
        }

        SettingRow {
            last: true
            label: "Keep awake by default"

            ToggleSwitch {
                checked: false
                onToggled: v => checked = v
            }
        }
    }
}
