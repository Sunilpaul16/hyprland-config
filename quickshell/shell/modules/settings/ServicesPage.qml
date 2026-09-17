import "../../services"
import "../../components"

// Services page
ScrollPage {
    id: root

    property string sectionKey: "all"
    property string pageTitle: "Services"

    title: root.pageTitle

    function shows(key: string): bool {
        return root.sectionKey === "all" || root.sectionKey === key;
    }

    // Format hour
    function formatHour(hour: int): string {
        if (!Time.use12Hour)
            return `${hour < 10 ? "0" : ""}${hour}:00`;
        if (hour === 0)
            return "12 am";
        if (hour === 12)
            return "12 pm";
        return hour < 12 ? `${hour} am` : `${hour - 12} pm`;
    }

    SectionLabel {
        visible: root.shows("notifications")
        text: "Popups & history"
    }

    SettingGroup {
        visible: root.shows("notifications")
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
            live: true
            label: "Keep across restarts"
            subtext: "Notification history survives a restart"

            ToggleSwitch {
                checked: Config.notifications.keepAcrossRestarts
                onToggled: v => Config.notifications.keepAcrossRestarts = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Popup position"

            SelectMenu {
                options: [
                    { value: "top-right", label: "Top right" },
                    { value: "top-left", label: "Top left" },
                    { value: "bottom-right", label: "Bottom right" },
                    { value: "bottom-left", label: "Bottom left" }
                ]
                current: Config.notifications.popupPosition
                onSelected: v => Config.notifications.popupPosition = v
            }
        }
    }

    SectionLabel {
        visible: root.shows("notifications")
        text: "Shell integration"
    }

    SettingGroup {
        visible: root.shows("notifications")

        SettingRow {
            first: true
            live: true
            label: "Show notification indicator"
            subtext: "Show the unread notification bell in the top bar"

            ToggleSwitch {
                checked: Config.bar.showNotificationIndicator
                onToggled: v => Config.bar.showNotificationIndicator = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Empty history image"
            subtext: "Shown in the sidebar when there are no notifications"

            ValueLabel {
                // Read-only
                text: Config.sidebar.noNotifsImage || "assets/dino.png"
            }
        }
    }

    SectionLabel {
        visible: root.shows("polling")
        text: "Polling"
    }

    SettingGroup {
        visible: root.shows("polling")
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

        SettingRow {
            live: true
            label: "Network status"
            subtext: "Ethernet link and VPN state"

            NumberControl {
                value: Config.polling.networkStatus
                from: 1000
                to: 30000
                stepSize: 1000
                suffix: " ms"
                onMoved: v => Config.polling.networkStatus = Math.round(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Network throughput"
            subtext: "Sampling rate for the speed graphs"

            NumberControl {
                value: Config.polling.networkUsage
                from: 500
                to: 10000
                stepSize: 250
                suffix: " ms"
                onMoved: v => Config.polling.networkUsage = Math.round(v)
            }
        }
    }

    SectionLabel {
        visible: root.shows("weather")
        text: "Weather"
    }

    SettingGroup {
        visible: root.shows("weather")
        SettingRow {
            first: true
            live: true
            label: "Location"
            subtext: Config.weather.latitude && Config.weather.longitude ? "Configured coordinates" : "Geolocated by IP at startup"

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
        visible: root.shows("recorder")
        text: "Screen recorder"
    }

    SettingGroup {
        visible: root.shows("recorder")
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
            live: true
            label: "Record audio"
            subtext: "Captures the default output alongside video"

            ToggleSwitch {
                checked: Config.recorder.audio
                onToggled: v => Config.recorder.audio = v
            }
        }
    }

    SectionLabel {
        visible: root.shows("power")
        text: "Idle & night light"
    }

    SettingGroup {
        visible: root.shows("power")
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
            live: true
            label: "Night light schedule"
            subtext: Config.nightLight.schedule ? `On from ${root.formatHour(Config.nightLight.startHour)} to ${root.formatHour(Config.nightLight.endHour)}` : "Night light stays under manual control"

            ToggleSwitch {
                checked: Config.nightLight.schedule
                onToggled: v => Config.nightLight.schedule = v
            }
        }

        SettingRow {
            live: true
            enabled: Config.nightLight.schedule
            opacity: enabled ? 1 : 0.5
            label: "Turns on at"

            NumberControl {
                value: Config.nightLight.startHour
                from: 0
                to: 23
                stepSize: 1
                displayText: root.formatHour(Config.nightLight.startHour)
                onMoved: v => Config.nightLight.startHour = Math.round(v)
            }
        }

        SettingRow {
            live: true
            enabled: Config.nightLight.schedule
            opacity: enabled ? 1 : 0.5
            label: "Turns off at"

            NumberControl {
                value: Config.nightLight.endHour
                from: 0
                to: 23
                stepSize: 1
                displayText: root.formatHour(Config.nightLight.endHour)
                onMoved: v => Config.nightLight.endHour = Math.round(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Keep awake by default"
            subtext: "Holds the inhibitor from the start of a session"

            ToggleSwitch {
                checked: Config.session.keepAwakeDefault
                onToggled: v => Config.session.keepAwakeDefault = v
            }
        }
    }
}
