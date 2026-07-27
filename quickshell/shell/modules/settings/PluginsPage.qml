import QtQuick
import QtQuick.Layouts
import "../../services"
import "../sidebarRight"

// Plugins page. Layout only — there is no plugin system in this shell, so this
// is a sketch of one rather than a view onto anything
ScrollPage {
    title: "Plugins"

    SectionLabel {
        text: "General"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Enable plugins"
            subtext: "Load QML from the plugin directory on start"

            ToggleSwitch {
                checked: false
                onToggled: v => checked = v
            }
        }

        SettingRow {
            label: "Plugin directory"

            ValueLabel {
                text: "~/.config/quickshell/plugins"
            }
        }

        SettingRow {
            last: true
            label: "Reload plugins"

            SelectPill {
                value: "Reload"
                icon: "refresh"
            }
        }
    }

    SectionLabel {
        text: "Installed"
    }

    // Empty state
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 150
        radius: 18
        color: Colors.surface

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "extension_off"
                color: Colors.outlineVariant
                font.pixelSize: 40
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No plugins installed"
                color: Colors.textMuted
                font.pixelSize: 15
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Drop a folder into the plugin directory to get started."
                color: Colors.outline
                font.pixelSize: 12
            }
        }
    }
}
