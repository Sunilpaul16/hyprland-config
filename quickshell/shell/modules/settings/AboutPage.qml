import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// About page. Every value here is real: SysInfo reads /etc and /proc directly,
// AboutInfo shells out for the three facts a file can't answer, and the display
// list comes from Quickshell.screens merged with Hyprland's monitor JSON
ScrollPage {
    id: root

    title: "About"

    // Subprocess-backed values load on first visit, not at shell startup
    Component.onCompleted: AboutInfo.load()

    // Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 30 * 2
        radius: 22
        color: Colors.layer

        ColumnLayout {
            id: hero

            anchors.centerIn: parent
            width: parent.width - 30 * 2
            spacing: 4

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: SysInfo.osGlyph
                font.family: Fonts.glyphFamily
                font.pixelSize: 52
                color: Colors.primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                text: SysInfo.osName
                font.pixelSize: 22
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: SysInfo.uptimeLong
                color: Colors.outline
                font.pixelSize: 13
            }
        }
    }

    SectionLabel {
        text: "System"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Operating system"

            ValueLabel {
                text: SysInfo.osName
            }
        }

        SettingRow {
            live: true
            label: "Kernel"

            ValueLabel {
                text: SysInfo.kernel || "Unknown"
            }
        }

        SettingRow {
            live: true
            label: "Hostname"

            ValueLabel {
                text: SysInfo.hostname || "Unknown"
            }
        }

        SettingRow {
            live: true
            label: "Uptime"

            ValueLabel {
                text: SysInfo.uptimeLong
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Compositor"

            ValueLabel {
                text: AboutInfo.hyprlandVersion ? `Hyprland ${AboutInfo.hyprlandVersion}` : "Hyprland"
            }
        }
    }

    SectionLabel {
        text: "Hardware"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Processor"

            ValueLabel {
                text: SysInfo.cpuModel || "Unknown"
            }
        }

        SettingRow {
            live: true
            label: "Graphics"

            ValueLabel {
                text: AboutInfo.gpuModel || "Unknown"
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Memory"

            ValueLabel {
                text: SysInfo.memoryTotalLabel || "Unknown"
            }
        }
    }

    SectionLabel {
        text: AboutInfo.displays.length === 1 ? "Display" : "Displays"
    }

    SettingGroup {
        Repeater {
            model: AboutInfo.displays

            SettingRow {
                required property int index
                required property var modelData

                first: index === 0
                last: index === AboutInfo.displays.length - 1
                live: true
                label: modelData.model ? `${modelData.name} · ${modelData.model}` : modelData.name

                ValueLabel {
                    text: modelData.refreshRate > 0 ? `${modelData.width}×${modelData.height} @ ${Math.round(modelData.refreshRate)} Hz` : `${modelData.width}×${modelData.height}`
                }
            }
        }
    }

    SectionLabel {
        text: "Shell"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Quickshell"

            ValueLabel {
                text: AboutInfo.quickshellVersion || "Unknown"
            }
        }

        SettingRow {
            live: true
            label: "Config"

            ValueLabel {
                text: Directories.repoRoot
            }
        }

        SettingRow {
            live: true
            label: "Settings file"

            ValueLabel {
                text: Directories.configFile
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Restart shell"
            subtext: "Same as SUPER+CTRL+R"

            SelectPill {
                value: "Restart"
                icon: "restart_alt"
                onClicked: Quickshell.execDetached(["bash", "-c", "pkill -x qs; qs -n -c shell"])
            }
        }
    }

    SectionLabel {
        text: "Credits"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "end-4/dots-hyprland"
            subtext: "Panel loader, focus grab, settings layout ideas"

            SelectPill {
                value: "GitHub"
                icon: "open_in_new"
                onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/end-4/dots-hyprland"])
            }
        }

        SettingRow {
            last: true
            live: true
            label: "caelestia-dots/shell"
            subtext: "Nexus settings vocabulary, dashboard card sizing"

            SelectPill {
                value: "GitHub"
                icon: "open_in_new"
                onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/caelestia-dots/shell"])
            }
        }
    }
}
