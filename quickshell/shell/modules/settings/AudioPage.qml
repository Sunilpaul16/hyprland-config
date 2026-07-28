import QtQuick
import "../../services"

// Audio page. Output/input/per-app are live against services/Audio.qml;
// the Behaviour and OSD sections are still mock — those would need config
// keys that don't exist yet
ScrollPage {
    id: root

    title: "Audio"

    readonly property var sinkOptions: Audio.sinks.map(n => ({ value: n.name, label: Audio.deviceDisplayName(n) }))
    readonly property var sourceOptions: Audio.sources.map(n => ({ value: n.name, label: Audio.deviceDisplayName(n) }))

    SectionLabel {
        text: "Output"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Output device"

            SelectMenu {
                options: root.sinkOptions
                current: Audio.sink?.name ?? ""
                placeholder: "No output device"
                onSelected: v => Audio.setSink(Audio.sinks.find(n => n.name === v))
            }
        }

        SettingRow {
            live: true
            label: "Volume"

            NumberControl {
                value: Audio.volume
                from: 0
                to: 1
                stepSize: 0.01
                displayScale: 100
                suffix: "%"
                labelWidth: 46
                onMoved: v => Audio.setVolume(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Mute output"

            ToggleSwitch {
                checked: Audio.muted
                onToggled: Audio.toggleMute()
            }
        }
    }

    SectionLabel {
        text: "Input"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Input device"

            SelectMenu {
                options: root.sourceOptions
                current: Audio.source?.name ?? ""
                placeholder: "No input device"
                onSelected: v => Audio.setSource(Audio.sources.find(n => n.name === v))
            }
        }

        SettingRow {
            live: true
            label: "Microphone volume"

            NumberControl {
                value: Audio.sourceVolume
                from: 0
                to: 1
                stepSize: 0.01
                displayScale: 100
                suffix: "%"
                labelWidth: 46
                onMoved: v => Audio.setSourceVolume(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Mute microphone"

            ToggleSwitch {
                checked: Audio.micMuted
                onToggled: Audio.toggleMicMute()
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
        text: "Playing now"
    }

    // Application streams — this list is whatever holds a stream right now,
    // so it being empty is the normal case, not a failure
    SettingGroup {
        Repeater {
            model: Audio.outputAppNodes

            AppVolumeRow {
                required property int index
                required property var modelData

                node: modelData
                first: index === 0
                last: index === Audio.outputAppNodes.length - 1
            }
        }

        SettingRow {
            visible: Audio.outputAppNodes.length === 0
            first: true
            last: true
            live: true
            label: "Nothing is playing"
            subtext: "Applications appear here while they hold an audio stream"
        }
    }

    SectionLabel {
        visible: Audio.inputAppNodes.length > 0
        text: "Recording now"
    }

    SettingGroup {
        Repeater {
            model: Audio.inputAppNodes

            AppVolumeRow {
                required property int index
                required property var modelData

                node: modelData
                first: index === 0
                last: index === Audio.inputAppNodes.length - 1
            }
        }
    }
}
