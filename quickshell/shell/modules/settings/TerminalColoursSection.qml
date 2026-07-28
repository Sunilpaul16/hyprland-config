import QtQuick
import QtQuick.Layouts
import "../../services"

// Terminal palette tuning — bends kitty's 16-colour ANSI set toward the accent.
// Spacing matches ScrollPage's own column so wrapping these two changes nothing
ColumnLayout {
    spacing: 14

    SectionLabel {
        text: "Terminal colours"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Harmony"
            subtext: "How far terminal hues shift toward the accent"

            NumberControl {
                value: Config.theming.terminalHarmony
                from: 0
                to: 1
                stepSize: 0.05
                decimals: 2
                onMoved: v => Config.theming.terminalHarmony = v
            }
        }

        SettingRow {
            live: true
            label: "Harmonize threshold"
            subtext: "Maximum hue angle allowed to shift"

            NumberControl {
                value: Config.theming.terminalHarmonizeThreshold
                from: 0
                to: 180
                stepSize: 5
                suffix: "°"
                onMoved: v => Config.theming.terminalHarmonizeThreshold = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Foreground boost"
            subtext: "Separates terminal text from its background"

            NumberControl {
                value: Config.theming.terminalFgBoost
                from: 0
                to: 1
                stepSize: 0.05
                decimals: 2
                onMoved: v => Config.theming.terminalFgBoost = v
            }
        }

        SettingRow {
            live: true
            label: "Window opacity"
            subtext: "kitty's background; needs a regenerate to apply"

            NumberControl {
                value: Config.theming.terminalOpacity
                from: 0.3
                to: 1
                stepSize: 0.05
                displayScale: 100
                decimals: 0
                suffix: "%"
                labelWidth: 46
                onMoved: v => Config.theming.terminalOpacity = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Always dark"
            subtext: "Keeps the terminal dark in light mode"

            ToggleSwitch {
                checked: Config.theming.terminalForceDark
                onToggled: v => Config.theming.terminalForceDark = v
            }
        }
    }
}
