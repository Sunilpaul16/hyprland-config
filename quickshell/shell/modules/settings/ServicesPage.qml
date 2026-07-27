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
            label: "CPU & memory"
            subtext: "services/SystemUsage.qml"

            SelectPill {
                value: "1000 ms"
            }
        }

        SettingRow {
            label: "GPU"
            subtext: "services/Gpu.qml"

            SelectPill {
                value: "2000 ms"
            }
        }

        SettingRow {
            label: "Storage"
            subtext: "services/Storage.qml"

            SelectPill {
                value: "10000 ms"
            }
        }

        SettingRow {
            last: true
            label: "Uptime"
            subtext: "services/SysInfo.qml"

            SelectPill {
                value: "60000 ms"
            }
        }
    }

    SectionLabel {
        text: "Weather"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Location"

            SelectPill {
                value: "Automatic"
            }
        }

        SettingRow {
            label: "Units"

            SelectPill {
                value: "Celsius"
            }
        }

        SettingRow {
            last: true
            label: "Refresh interval"

            SelectPill {
                value: "15 min"
            }
        }
    }

    SectionLabel {
        text: "Screen recorder"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Default mode"
            subtext: "services/Recorder.qml"

            SelectPill {
                value: "Full screen"
            }
        }

        SettingRow {
            label: "Save to"

            ValueLabel {
                text: "~/Videos/recordings"
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
            label: "Night light temperature"
            subtext: "services/NightLightState.qml"

            SelectPill {
                value: "5200 K"
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
