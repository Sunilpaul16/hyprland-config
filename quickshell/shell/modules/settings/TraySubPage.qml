import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../../services"
import "../../components"

// Tray visibility page
ScrollPage {
    id: root

    title: "Tray items"
    isSubPage: true

    // Hidden ids
    readonly property var hiddenIds: Config.bar.trayHidden.split(",").map(s => s.trim().toLowerCase()).filter(s => s.length > 0)
    readonly property var liveIds: SystemTray.items.values.map(i => i.id.toLowerCase())
    readonly property var orphanedIds: root.hiddenIds.filter(id => !root.liveIds.includes(id))

    function setHidden(id: string, hidden: bool): void {
        const lower = id.toLowerCase();
        const next = root.hiddenIds.filter(i => i !== lower);
        if (hidden)
            next.push(lower);
        Config.bar.trayHidden = next.join(",");
    }

    SectionLabel {
        text: "Running"
    }

    StyledText {
        visible: SystemTray.items.values.length === 0
        text: "No applications are registering a tray icon."
        color: Colors.textMuted
        font.pixelSize: Motion.fontSize.label
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    SettingGroup {
        visible: SystemTray.items.values.length > 0

        Repeater {
            model: SystemTray.items.values

            SettingRow {
                id: liveRow

                required property SystemTrayItem modelData
                required property int index

                first: index === 0
                last: index === SystemTray.items.values.length - 1
                live: true
                label: liveRow.modelData.title || liveRow.modelData.id
                subtext: liveRow.modelData.id

                ToggleSwitch {
                    checked: !root.hiddenIds.includes(liveRow.modelData.id.toLowerCase())
                    onToggled: v => root.setHidden(liveRow.modelData.id, !v)
                }
            }
        }
    }

    // Offline hidden ids
    SectionLabel {
        visible: root.orphanedIds.length > 0
        text: "Hidden, not running"
    }

    SettingGroup {
        visible: root.orphanedIds.length > 0

        Repeater {
            model: root.orphanedIds

            SettingRow {
                id: orphanRow

                required property string modelData
                required property int index

                first: index === 0
                last: index === root.orphanedIds.length - 1
                live: true
                label: orphanRow.modelData
                subtext: "Not currently registered"

                ToggleSwitch {
                    checked: false
                    onToggled: root.setHidden(orphanRow.modelData, false)
                }
            }
        }
    }
}
