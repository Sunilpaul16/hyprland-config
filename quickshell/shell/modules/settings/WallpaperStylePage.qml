import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../services"
import "../sidebarRight"

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
                radius: 18
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.surface
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
            text: "Browse"
            highlighted: true
            onClicked: {
                SettingsState.open = false;
                LauncherState.openWallpaper();
            }
        }

        PillButton {
            live: true
            icon: "shuffle"
            text: "Random"
            onClicked: Wallpapers.applyRandom()
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
            label: "Transparency"
            subtext: "Base 0.9, layers 0.3"

            ToggleSwitch {
                checked: false
                onToggled: v => checked = v
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
            label: "Scheme"
            subtext: "switchwall hardcodes scheme-tonal-spot"

            SelectPill {
                value: "Tonal spot"
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
