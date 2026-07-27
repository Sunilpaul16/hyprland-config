import QtQuick
import QtQuick.Layouts
import "../../services"

// Panels page. Mostly layout — the rows track keys that already exist in
// services/Config.qml plus the panels that have no config surface yet.
// The Motion section is the exception: it reads AND writes live config, and
// is the worked example for wiring the rest
ScrollPage {
    title: "Panels"

    SectionLabel {
        text: "Motion"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Animation speed"
            subtext: "Divides every duration in the shell"

            RowLayout {
                spacing: 12

                ValueLabel {
                    // Fixed width so the slider doesn't shift as digits change
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: `${Config.motion.speed.toFixed(2)}×`
                }

                SettingSlider {
                    from: 0.5
                    to: 2
                    stepSize: 0.05
                    value: Config.motion.speed
                    onMoved: v => Config.motion.speed = v
                }
            }
        }

        SettingRow {
            last: true
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
            label: "Bar height"
            subtext: "Config.bar.height"

            SelectPill {
                value: "40 px"
            }
        }

        SettingRow {
            label: "12-hour clock"
            subtext: "Config.time.use12Hour"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
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
            label: "Panel width"
            subtext: "Config.dashboard.panel.widthMode"

            SelectPill {
                value: "Auto"
            }
        }

        SettingRow {
            label: "Panel height"
            subtext: "Config.dashboard.panel.heightMode"

            SelectPill {
                value: "Auto"
            }
        }

        SettingRow {
            label: "Default tab"

            SelectPill {
                value: "Dashboard"
            }
        }

        SettingRow {
            label: "Media card animation"
            subtext: "Config.dashboard.media.gifEnabled"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            last: true
            label: "Animation speed"
            subtext: "Config.dashboard.media.gifSpeed"

            SettingSlider {
                value: 0.5
                onMoved: nv => value = nv
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
            label: "Notifications watermark"
            subtext: "Config.sidebar.noNotifsImage"

            ValueLabel {
                text: "assets/dino.png"
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
            label: "Session drawer auto-close"
            subtext: "Config.session.autoCloseDuration"

            SelectPill {
                value: "5000 ms"
            }
        }
    }
}
