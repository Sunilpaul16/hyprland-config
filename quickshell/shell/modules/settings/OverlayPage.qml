import "../../services"
import "../../components"

// Overlay widgets page
ScrollPage {
    id: root

    title: "Overlay widgets"

    SectionLabel {
        text: "Canvas"
    }

    SettingGroup {
        SettingRow {
            first: true
            last: true
            live: true
            label: "Dim the screen while editing"
            subtext: "Applies while SUPER + O is open"

            ToggleSwitch {
                checked: Config.overlay.darkenScreen
                onToggled: v => Config.overlay.darkenScreen = v
            }
        }
    }

    SectionLabel {
        text: "Crosshair"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Colour"

            SelectPill {
                options: [
                    { value: "#00ff66", label: "Green" },
                    { value: "#ffffff", label: "White" },
                    { value: "#00ffff", label: "Cyan" },
                    { value: "#ff00ff", label: "Magenta" },
                    { value: "#ffff00", label: "Yellow" },
                    { value: "#ff3b30", label: "Red" }
                ]
                current: Config.overlay.crosshair.color
                onSelected: v => Config.overlay.crosshair.color = v
            }
        }

        SettingRow {
            live: true
            label: "Opacity"

            SettingSlider {
                value: Config.overlay.crosshair.opacity
                from: 0.1
                to: 1
                stepSize: 0.05
                onMoved: v => Config.overlay.crosshair.opacity = v
            }
        }

        SettingRow {
            live: true
            label: "Centre gap"
            subtext: "Distance from the centre to each line"

            NumberControl {
                value: Config.overlay.crosshair.gap
                from: 0
                to: 30
                stepSize: 1
                suffix: " px"
                onMoved: v => Config.overlay.crosshair.gap = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Line length"

            NumberControl {
                value: Config.overlay.crosshair.length
                from: 1
                to: 40
                stepSize: 1
                suffix: " px"
                onMoved: v => Config.overlay.crosshair.length = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Line thickness"

            NumberControl {
                value: Config.overlay.crosshair.thickness
                from: 1
                to: 10
                stepSize: 1
                suffix: " px"
                onMoved: v => Config.overlay.crosshair.thickness = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Outline"
            subtext: "Keeps the crosshair readable on light scenes"

            ToggleSwitch {
                checked: Config.overlay.crosshair.outline
                onToggled: v => Config.overlay.crosshair.outline = v
            }
        }

        SettingRow {
            live: true
            label: "Centre dot"

            ToggleSwitch {
                checked: Config.overlay.crosshair.centerDot
                onToggled: v => Config.overlay.crosshair.centerDot = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Centre dot size"

            NumberControl {
                value: Config.overlay.crosshair.dotSize
                from: 1
                to: 12
                stepSize: 1
                suffix: " px"
                onMoved: v => Config.overlay.crosshair.dotSize = Math.round(v)
            }
        }
    }

    SectionLabel {
        text: "Floating image"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Image"
            subtext: "Relative paths resolve against the config repo"

            ValueLabel {
                // Read-only
                text: Config.overlay.floatingImage.source || "none set"
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Scale"
            subtext: "Also set by scrolling over the image"

            SettingSlider {
                value: Config.overlay.floatingImage.scale
                from: 0.1
                to: 5
                stepSize: 0.1
                onMoved: v => Config.overlay.floatingImage.scale = v
            }
        }
    }
}
