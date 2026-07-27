import QtQuick.Layouts

// Audio page. Layout only — rows mirror services/Audio.qml's sink/source
// bindings and the volumeOsd module, nothing is wired
ScrollPage {
    title: "Audio"

    SectionLabel {
        text: "Output"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Output device"

            SelectPill {
                value: "Family 17h HD Audio"
            }
        }

        SettingRow {
            label: "Volume"

            SettingSlider {
                value: 0.62
                onMoved: nv => value = nv
            }
        }

        SettingRow {
            last: true
            label: "Mute output"

            ToggleSwitch {
                checked: false
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "Input"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Input device"

            SelectPill {
                value: "Blue Yeti"
            }
        }

        SettingRow {
            label: "Microphone volume"

            SettingSlider {
                value: 0.45
                onMoved: nv => value = nv
            }
        }

        SettingRow {
            last: true
            label: "Mute microphone"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "Behaviour"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Volume step"
            subtext: "Applied by the media keys"

            SelectPill {
                value: "5%"
            }
        }

        SettingRow {
            label: "Allow over 100%"
            subtext: "Lets the sink boost past unity gain"

            ToggleSwitch {
                checked: false
                onToggled: v => checked = v
            }
        }

        SettingRow {
            last: true
            label: "Unmute on volume change"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "On-screen display"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Show volume OSD"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            label: "Dismiss after"

            SelectPill {
                value: "1500 ms"
            }
        }

        SettingRow {
            last: true
            label: "Position"

            SelectPill {
                value: "Bottom centre"
            }
        }
    }

    SectionLabel {
        text: "Per-app volume"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Firefox"

            SettingSlider {
                value: 0.8
                onMoved: nv => value = nv
            }
        }

        SettingRow {
            last: true
            label: "Spotify"

            SettingSlider {
                value: 0.55
                onMoved: nv => value = nv
            }
        }
    }
}
