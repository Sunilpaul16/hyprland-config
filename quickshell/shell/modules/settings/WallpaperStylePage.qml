import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../services"
import "../../components"

// Wallpaper and style page
ScrollPage {
    id: root

    title: "Wallpaper & style"

    // Apply display toggle
    Process {
        id: wallpaperDisplayProc
    }

    function applyWallpaperDisplay(on: bool): void {
        wallpaperDisplayProc.command = on ? ["sh", "-c", "switchwall --preview --force-display \"$(cat \"$HOME/.local/state/quickshell/current_wallpaper\")\""] : ["pkill", "-f", "mpvpaper"];
        wallpaperDisplayProc.running = true;
    }

    WallpaperPreviewHeader {
        Layout.fillWidth: true
        cappedWidth: root.cappedWidth
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
            live: true
            label: "Display wallpaper"
            subtext: "Off shows the themed background colour instead"

            ToggleSwitch {
                checked: Config.wallpaper.display
                onToggled: v => {
                    Config.wallpaper.display = v;
                    root.applyWallpaperDisplay(v);
                }
            }
        }

        SettingRow {
            live: true
            // Run end
            last: !Config.appearance.transparency
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
            last: true
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
    }
    // No dark boolean

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
            label: "Colour source"
            subtext: "Presets ignore the wallpaper"

            SelectMenu {
                options: [
                    { value: "dynamic", label: "Wallpaper" },
                    { value: "preset", label: "Preset" }
                ]
                current: Theme.usingPreset ? "preset" : "dynamic"
                onSelected: v => {
                    if (v === "dynamic")
                        Theme.setDynamic();
                    else
                        SettingsState.subPage = "schemes";
                }
            }
        }

        SettingRow {
            live: true
            enabled: !Theme.usingPreset
            opacity: enabled ? 1 : 0.5
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
            subtext: Theme.lastRunFailed ? "Theme generation failed" : "Re-runs switchwall on the current wallpaper"

            SelectPill {
                enabled: !Theme.busy
                opacity: enabled ? 1 : 0.5
                value: Theme.busy ? "Working…" : (Theme.lastRunFailed ? "Failed" : "Regenerate")
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

    TerminalColoursSection {
        Layout.fillWidth: true
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
        // Curated shortlist
        SettingRow {
            first: true
            live: true
            label: "Interface font"

            SelectMenu {
                options: Fonts.interfaceOptions
                current: Fonts.interfaceFamily
                onSelected: v => Config.appearance.fontInterface = v
            }
        }

        // Icon glyphs
        SettingRow {
            last: true
            live: true
            label: "Glyph font"

            SelectMenu {
                options: Fonts.glyphOptions
                current: Fonts.glyphFamily
                onSelected: v => Config.appearance.fontGlyph = v
            }
        }
    }
}

