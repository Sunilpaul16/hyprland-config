import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Quick toggles page
ScrollPage {
    id: root

    title: "Quick toggles"
    isSubPage: true

    SectionLabel {
        text: "Visible"
    }

    SettingGroup {
        Repeater {
            model: QuickToggles.orderedVisible

            SettingRow {
                id: visibleRow

                required property var modelData
                required property int index

                first: index === 0
                last: index === QuickToggles.orderedVisible.length - 1
                live: true
                label: QuickToggles.nameFor(visibleRow.modelData.type)

                RowLayout {
                    spacing: Motion.spacing.medium

                    // Reorder
                    IconAction {
                        enabled: visibleRow.index > 0
                        opacity: enabled ? 1 : 0.3
                        implicitWidth: 30
                        implicitHeight: 30
                        iconName: "keyboard_arrow_up"
                        iconSize: Motion.fontSize.display
                        onTriggered: QuickToggles.moveToggle(visibleRow.modelData.type, -1)
                    }

                    IconAction {
                        enabled: visibleRow.index < QuickToggles.orderedVisible.length - 1
                        opacity: enabled ? 1 : 0.3
                        implicitWidth: 30
                        implicitHeight: 30
                        iconName: "keyboard_arrow_down"
                        iconSize: Motion.fontSize.display
                        onTriggered: QuickToggles.moveToggle(visibleRow.modelData.type, 1)
                    }

                    SelectPill {
                        options: [{ value: "small", label: "Small" }, { value: "large", label: "Large" }]
                        current: visibleRow.modelData.size
                        onSelected: v => QuickToggles.setSize(visibleRow.modelData.type, v)
                    }

                    ToggleSwitch {
                        checked: true
                        onToggled: QuickToggles.removeToggle(visibleRow.modelData.type)
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: QuickToggles.orderedVisible.length === 1
        text: "The last remaining toggle can't be hidden."
        color: Colors.textMuted
        font.pixelSize: Motion.fontSize.label
        wrapMode: Text.WordWrap
    }

    SectionLabel {
        visible: QuickToggles.hidden.length > 0
        text: "Hidden"
    }

    SettingGroup {
        visible: QuickToggles.hidden.length > 0

        Repeater {
            model: QuickToggles.hidden

            SettingRow {
                id: hiddenRow

                required property var modelData
                required property int index

                first: index === 0
                last: index === QuickToggles.hidden.length - 1
                live: true
                label: hiddenRow.modelData.name

                ToggleSwitch {
                    checked: false
                    onToggled: QuickToggles.addToggle(hiddenRow.modelData.id)
                }
            }
        }
    }
}
