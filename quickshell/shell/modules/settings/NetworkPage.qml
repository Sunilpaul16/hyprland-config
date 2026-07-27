import QtQuick.Layouts

// Network page. Layout only — rows mirror what services/Wifi.qml,
// EthernetStatus.qml and NetworkUsage.qml already expose, nothing is wired
ScrollPage {
    title: "Network"

    SectionLabel {
        text: "Wi-Fi"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Wi-Fi"
            subtext: "Turn the adapter on or off"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            label: "Connected network"

            ValueLabel {
                text: "Not connected"
            }
        }

        SettingRow {
            label: "Available networks"
            subtext: "Scan and connect"

            SelectPill {
                value: "Browse"
                icon: "chevron_right"
            }
        }

        SettingRow {
            last: true
            label: "Connect automatically"
            subtext: "Rejoin known networks in range"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "Ethernet"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Interface"

            ValueLabel {
                text: "enp5s0"
            }
        }

        SettingRow {
            label: "Status"

            ValueLabel {
                text: "Connected"
            }
        }

        SettingRow {
            last: true
            label: "Open connection editor"
            subtext: "Hands off to nm-connection-editor"

            SelectPill {
                value: "Open"
                icon: "open_in_new"
            }
        }
    }

    SectionLabel {
        text: "Usage"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Track throughput"
            subtext: "Feeds the dashboard's Network card"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            label: "Monitored interface"

            SelectPill {
                value: "Automatic"
            }
        }

        SettingRow {
            last: true
            label: "History length"
            subtext: "Samples kept for the graph"

            SelectPill {
                value: "30"
            }
        }
    }
}
