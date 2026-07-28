import QtQuick
import "../../services"

// Panels page. Rows naming a real Config key read and write it live; the
// rest hold local state and are placeholders for panels that have no config
// surface yet (tray/title visibility, launcher limits, quick-toggle editing)
ScrollPage {
    title: "Panels"

    SectionLabel {
        text: "Motion"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Animation speed"
            subtext: "Divides every duration in the shell"

            NumberControl {
                value: Config.motion.speed
                from: 0.5
                to: 2
                stepSize: 0.05
                decimals: 2
                suffix: "×"
                onMoved: v => Config.motion.speed = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Reduce motion"
            subtext: "Collapses all animation durations to zero"

            ToggleSwitch {
                checked: Config.motion.reduced
                onToggled: value => Config.motion.reduced = value
            }
        }
    }

    SectionLabel {
        text: "Bar"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Bar height"
            subtext: "Height of the top bar"

            NumberControl {
                value: Config.bar.height
                from: 24
                to: 64
                stepSize: 1
                suffix: " px"
                onMoved: v => Config.bar.height = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "12-hour clock"
            subtext: "Show AM/PM instead of 24-hour time"

            ToggleSwitch {
                checked: Config.time.use12Hour
                onToggled: v => Config.time.use12Hour = v
            }
        }

        SettingRow {
            label: "Show system tray"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            last: true
            label: "Show active window title"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "Dashboard"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Panel width"
            subtext: "Auto measures the content; fixed uses a set size"

            SelectPill {
                options: [{ value: "auto", label: "Auto" }, { value: "fixed", label: "Fixed" }]
                current: Config.dashboard.panel.widthMode
                onSelected: v => Config.dashboard.panel.widthMode = v
            }
        }

        SettingRow {
            live: true
            label: "Panel height"
            subtext: "Auto measures the content; fixed uses a set size"

            SelectPill {
                options: [{ value: "auto", label: "Auto" }, { value: "fixed", label: "Fixed" }]
                current: Config.dashboard.panel.heightMode
                onSelected: v => Config.dashboard.panel.heightMode = v
            }
        }

        SettingRow {
            label: "Default tab"

            SelectPill {
                value: "Dashboard"
            }
        }

        SettingRow {
            live: true
            label: "Media card animation"
            subtext: "The bongocat gif on the dashboard's Media card"

            ToggleSwitch {
                checked: Config.dashboard.media.gifEnabled
                onToggled: v => Config.dashboard.media.gifEnabled = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Animation speed"
            subtext: "Gif playback rate (1.00 is native)"

            NumberControl {
                value: Config.dashboard.media.gifSpeed
                from: 0.25
                to: 3
                stepSize: 0.05
                decimals: 2
                suffix: "×"
                onMoved: v => Config.dashboard.media.gifSpeed = v
            }
        }
    }

    SectionLabel {
        text: "Launcher"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Fuzzy matching"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            label: "Maximum results"

            SelectPill {
                value: "8"
            }
        }

        SettingRow {
            last: true
            label: "Clipboard history entries"

            SelectPill {
                value: "100"
            }
        }
    }

    SectionLabel {
        text: "Sidebar"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Quick toggles"
            subtext: "Choose which pills are shown"

            SelectPill {
                value: "Edit"
                icon: "chevron_right"
            }
        }

        SettingRow {
            live: true
            label: "Notifications watermark"
            subtext: "Shown when the sidebar has no notifications"

            ValueLabel {
                // Read-only: editing a path needs a text field, which the
                // panel has no control for yet
                text: Config.sidebar.noNotifsImage || "assets/dino.png"
            }
        }

        SettingRow {
            last: true
            label: "Close when settings opens"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "Overview & session"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Live window thumbnails"
            subtext: "Screencopy previews in the overview"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Session drawer auto-close"
            subtext: "How long the drawer stays open unhovered"

            NumberControl {
                value: Config.session.autoCloseDuration
                from: 1000
                to: 15000
                stepSize: 500
                suffix: " ms"
                onMoved: v => Config.session.autoCloseDuration = Math.round(v)
            }
        }
    }
}
