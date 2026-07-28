import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../services"
import "../../components"

// Wallpaper & style page. Layout only — the pills navigate nowhere and the
// switches hold their own state rather than writing any config
ScrollPage {
    id: root

    title: "Wallpaper & style"

    // Wallpaper preview
    Item {
        id: preview
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Math.min(root.cappedWidth * 0.72, 470)
        implicitHeight: Math.round(implicitWidth * 9 / 16)

        // Rounded via OpacityMask on a plain Image — a
        // ClippingRectangle renders nothing inside these overlays
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: preview.width
                height: preview.height
                radius: Motion.rounding.large
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.layer
        }

        Image {
            id: previewImage

            anchors.fill: parent
            source: Wallpapers.currentPreview
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }

        // Fallback while the wallpaper (or its thumb) is missing
        ColumnLayout {
            anchors.centerIn: parent
            visible: previewImage.status !== Image.Ready
            spacing: 4

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "hide_image"
                color: Colors.textMuted
                font.pixelSize: 42
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No wallpaper preview"
                color: Colors.textMuted
                font.pixelSize: 13
            }
        }
    }

    // Sub-navigation
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10

        PillButton {
            live: true
            icon: "wallpaper"
            text: "Wallpapers"
            highlighted: true
            onClicked: SettingsState.openSubPage("wallpapers")
        }

        // caelestia's equivalent opens a "page under construction" stub, so
        // there is nothing to port behind this one yet
        PillButton {
            icon: "palette"
            text: "Colours"
        }
    }

    SectionLabel {
        text: "Wallpaper"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Current"

            ValueLabel {
                Layout.maximumWidth: 320
                text: Wallpapers.current ? Wallpapers.current.split("/").pop() : "None set"
            }
        }

        SettingRow {
            live: true
            label: "Folder"

            ValueLabel {
                Layout.maximumWidth: 320
                text: Directories.wallpaperDir
            }
        }

        SettingRow {
            label: "Display wallpaper"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }

        SettingRow {
            live: true
            label: "Transparency"
            subtext: "Translucent panel backgrounds, blurred by Hyprland"

            ToggleSwitch {
                checked: Config.appearance.transparency
                onToggled: v => Config.appearance.transparency = v
            }
        }

        SettingRow {
            live: true
            visible: Config.appearance.transparency
            label: "Card opacity"
            subtext: "Cards and pills; lower than the panel or they read as solid"

            NumberControl {
                value: Config.appearance.layerOpacity
                from: 0.2
                to: 1
                stepSize: 0.05
                displayScale: 100
                decimals: 0
                suffix: "%"
                labelWidth: 46
                onMoved: v => Config.appearance.layerOpacity = v
            }
        }

        SettingRow {
            live: true
            visible: Config.appearance.transparency
            label: "Panel opacity"
            subtext: "The panel background behind the cards"

            NumberControl {
                value: Config.appearance.panelOpacity
                from: 0.3
                to: 1
                stepSize: 0.05
                displayScale: 100
                decimals: 0
                suffix: "%"
                labelWidth: 46
                onMoved: v => Config.appearance.panelOpacity = v
            }
        }

        SettingRow {
            last: true
            label: "Dark theme"

            ToggleSwitch {
                checked: true
                onToggled: v => checked = v
            }
        }
    }

    SectionLabel {
        text: "Colours"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Colour mode"
            subtext: "Automatic picks by wallpaper brightness"

            SelectPill {
                enabled: !Theme.busy
                opacity: enabled ? 1 : 0.5
                options: [{ value: "auto", label: "Automatic" }, { value: "light", label: "Light" }, { value: "dark", label: "Dark" }]
                current: Theme.mode
                onSelected: v => Theme.setMode(v)
            }
        }

        SettingRow {
            live: true
            label: "Scheme"
            subtext: "Automatic picks one to suit the wallpaper"

            SelectMenu {
                options: [
                    { value: "auto", label: "Automatic" },
                    { value: "scheme-tonal-spot", label: "Tonal spot" },
                    { value: "scheme-vibrant", label: "Vibrant" },
                    { value: "scheme-expressive", label: "Expressive" },
                    { value: "scheme-content", label: "Content" },
                    { value: "scheme-fidelity", label: "Fidelity" },
                    { value: "scheme-fruit-salad", label: "Fruit salad" },
                    { value: "scheme-monochrome", label: "Monochrome" },
                    { value: "scheme-neutral", label: "Neutral" },
                    { value: "scheme-rainbow", label: "Rainbow" }
                ]
                current: Config.theming.scheme
                onSelected: v => Config.theming.scheme = v
            }
        }

        SettingRow {
            live: true
            label: "Preview delay"
            subtext: "Settle time before a carousel pick is applied"

            NumberControl {
                value: Config.wallpaper.previewDelay
                from: 0
                to: 1000
                stepSize: 50
                suffix: " ms"
                onMoved: v => Config.wallpaper.previewDelay = Math.round(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Regenerate theme"
            subtext: "Re-runs switchwall on the current wallpaper"

            SelectPill {
                enabled: !Theme.busy
                opacity: enabled ? 1 : 0.5
                value: Theme.busy ? "Working…" : "Regenerate"
                icon: "refresh"
                onClicked: Theme.regenerate()
            }
        }
    }

    SectionLabel {
        text: "Palette"
    }

    ColourSwatches {
        Layout.fillWidth: true
    }

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

    SettingRow {
        live: true
        first: true
        last: true
        label: "Apply colour changes"
        subtext: "Scheme and terminal settings take effect on the next generation"

        SelectPill {
            enabled: !Theme.busy
            opacity: enabled ? 1 : 0.5
            value: Theme.busy ? "Working…" : "Regenerate"
            icon: "refresh"
            onClicked: Theme.regenerate()
        }
    }

    SectionLabel {
        text: "Fonts"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Interface font"

            SelectPill {
                value: "Rubik"
            }
        }

        SettingRow {
            last: true
            label: "Monospace font"

            SelectPill {
                value: "JetBrainsMono Nerd Font"
            }
        }
    }
}
