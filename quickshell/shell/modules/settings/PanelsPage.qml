import QtQuick.Layouts

// Panels page. Layout only — the rows track keys that already exist in
// services/Config.qml plus the panels that have no config surface yet
ScrollPage {
    title: "Panels"

    SectionLabel {
        text: "Bar"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Bar height"
            subtext: "Config.barHeight"

            SelectPill {
                value: "40 px"
            }
        }

        SettingRow {
            label: "12-hour clock"
            subtext: "Config.use12Hour"

            ToggleSwitch {
                checked: true
            }
        }

        SettingRow {
            label: "Show system tray"

            ToggleSwitch {
                checked: true
            }
        }

        SettingRow {
            last: true
            label: "Show active window title"

            ToggleSwitch {
                checked: true
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
            subtext: "Config.dashboardPanelWidthMode"

            SelectPill {
                value: "Auto"
            }
        }

        SettingRow {
            label: "Panel height"
            subtext: "Config.dashboardPanelHeightMode"

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
            subtext: "Config.dashboardMediaGifEnabled"

            ToggleSwitch {
                checked: true
            }
        }

        SettingRow {
            last: true
            label: "Animation speed"
            subtext: "Config.dashboardMediaGifSpeed"

            SettingSlider {
                value: 0.5
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
            subtext: "Config.sidebarNoNotifsImage"

            ValueLabel {
                text: "assets/dino.png"
            }
        }

        SettingRow {
            last: true
            label: "Close when settings opens"

            ToggleSwitch {
                checked: true
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
            }
        }

        SettingRow {
            last: true
            label: "Session drawer auto-close"
            subtext: "Config.sessionAutoCloseDuration"

            SelectPill {
                value: "5000 ms"
            }
        }
    }
}
