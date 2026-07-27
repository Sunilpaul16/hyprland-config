import QtQuick.Layouts

// Updates page. Layout only — no checker service exists yet, so every row here
// is a stand-in for one that would need building
ScrollPage {
    title: "Updates"

    SectionLabel {
        text: "Checking"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Check automatically"

            ToggleSwitch {
                checked: true
            }
        }

        SettingRow {
            label: "Check every"

            SelectPill {
                value: "6 hours"
            }
        }

        SettingRow {
            label: "Last checked"

            ValueLabel {
                text: "42 minutes ago"
            }
        }

        SettingRow {
            last: true
            label: "Check now"

            SelectPill {
                value: "Refresh"
                icon: "refresh"
            }
        }
    }

    SectionLabel {
        text: "Sources"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Official repositories"
            subtext: "pacman"

            ValueLabel {
                text: "12 pending"
            }
        }

        SettingRow {
            label: "AUR"
            subtext: "Helper used to query and build"

            SelectPill {
                value: "paru"
            }
        }

        SettingRow {
            last: true
            label: "Flatpak"

            ToggleSwitch {
                checked: false
            }
        }
    }

    SectionLabel {
        text: "Notifications"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Notify when updates land"

            ToggleSwitch {
                checked: true
            }
        }

        SettingRow {
            label: "Show count in the bar"

            ToggleSwitch {
                checked: false
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
