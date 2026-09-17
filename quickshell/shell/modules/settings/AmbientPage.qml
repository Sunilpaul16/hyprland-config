import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

ScrollPage {
    id: root

    title: "Ambient desktop"

    SectionLabel { text: "Atmosphere" }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 108
        radius: Motion.rounding.large
        clip: true

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: AmbientState.topTint }
            GradientStop { position: 1; color: AmbientState.bottomTint }
        }

        Column {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 18
            spacing: 2

            StyledText {
                text: AmbientState.statusLabel
                color: "white"
                font.pixelSize: Motion.fontSize.title
                font.bold: true
                style: Text.Outline
                styleColor: "#66000000"
            }

            StyledText {
                text: Config.ambient.mode === "auto" ? `Sunrise ${Weather.sunrise} · sunset ${Weather.sunset}` : "Manual preview"
                color: "white"
                font.pixelSize: Motion.fontSize.body
                style: Text.Outline
                styleColor: "#66000000"
            }
        }
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Ambient mode"
            subtext: "Tint only the wallpaper layer"

            ToggleSwitch {
                checked: Config.ambient.enabled
                onToggled: value => Config.ambient.enabled = value
            }
        }

        SettingRow {
            live: true
            label: "Phase"
            subtext: "Automatic follows the local time"

            SelectPill {
                options: [
                    { value: "auto", label: "Automatic" },
                    { value: "dawn", label: "Dawn" },
                    { value: "day", label: "Day" },
                    { value: "dusk", label: "Dusk" },
                    { value: "night", label: "Night" }
                ]
                current: Config.ambient.mode
                onSelected: value => Config.ambient.mode = value
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Intensity"
            subtext: `${Math.round(Config.ambient.intensity * 100)}%`

            SettingSlider {
                value: Config.ambient.intensity
                from: 0
                to: 1
                stepSize: 0.05
                onMoved: value => Config.ambient.intensity = value
            }
        }
    }

    SectionLabel { text: "Context" }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Use sunrise and sunset"
            subtext: "Falls back to 07:00 and 19:00 until weather loads"

            ToggleSwitch {
                checked: Config.ambient.useSunTimes
                onToggled: value => Config.ambient.useSunTimes = value
            }
        }

        SettingRow {
            live: true
            label: "React to weather"
            subtext: "Subtle clear, rain, snow and storm colouring"

            ToggleSwitch {
                checked: Config.ambient.weatherReactive
                onToggled: value => Config.ambient.weatherReactive = value
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Reduce on battery"
            subtext: "Uses a softer tint while discharging"

            ToggleSwitch {
                checked: Config.ambient.reduceOnBattery
                onToggled: value => Config.ambient.reduceOnBattery = value
            }
        }
    }

    SectionLabel { text: "Priority" }

    SettingGroup {
        SettingRow {
            first: true
            last: true
            live: true
            label: "Automatic overrides"
            subtext: "Focus mode becomes calmer; game mode pauses the ambient layer"

            ValueLabel { text: AmbientState.statusLabel }
        }
    }

    SectionLabel { text: "Weather" }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Location"
            subtext: Config.weather.latitude && Config.weather.longitude ? "Configured coordinates" : "Geolocated by IP at startup"

            ValueLabel {
                text: Weather.city || "Locating…"
            }
        }

        SettingRow {
            live: true
            label: "Units"

            SelectPill {
                options: [{ value: "celsius", label: "Celsius" }, { value: "fahrenheit", label: "Fahrenheit" }]
                current: Config.weather.units
                onSelected: v => Config.weather.units = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Refresh interval"

            NumberControl {
                value: Config.weather.refreshMinutes
                from: 5
                to: 240
                stepSize: 5
                suffix: " min"
                onMoved: v => Config.weather.refreshMinutes = Math.round(v)
            }
        }
    }
}
