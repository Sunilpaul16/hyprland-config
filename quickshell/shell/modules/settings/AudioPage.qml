import QtQuick
import "../../services"

// Audio page. Devices, levels, per-app and the volume-step/unmute behaviour
// are live against services/Audio.qml; the OSD section and the over-100%
// boost are still mock — the shell has no path for either yet
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
            live: true
            label: "Volume step"
            subtext: "Applied by the media keys and scroll"

            NumberControl {
                value: Config.audio.volumeStep
                from: 0.01
                to: 0.25
                stepSize: 0.01
                displayScale: 100
                decimals: 0
                suffix: "%"
                labelWidth: 46
                onMoved: v => Config.audio.volumeStep = v
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
            live: true
            label: "Unmute on volume change"
            subtext: "Raising the volume clears mute"

            ToggleSwitch {
                checked: Config.audio.unmuteOnChange
                onToggled: v => Config.audio.unmuteOnChange = v
            }
        }
    }

    SectionLabel {
        text: "On-screen display"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Show volume OSD"

            ToggleSwitch {
                checked: Config.audio.osdEnabled
                onToggled: v => Config.audio.osdEnabled = v
            }
        }

        SettingRow {
            live: true
            label: "Dismiss after"

            NumberControl {
                value: Config.audio.osdTimeout
                from: 500
                to: 5000
                stepSize: 250
                suffix: " ms"
                onMoved: v => Config.audio.osdTimeout = Math.round(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Position"

            SelectPill {
                options: [
                    { value: "right", label: "Right edge" },
                    { value: "left", label: "Left edge" }
                ]
                current: Config.audio.osdEdge
                onSelected: v => Config.audio.osdEdge = v
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
