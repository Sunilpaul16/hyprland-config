import QtQuick
import QtQuick.Layouts
import "../../services"
import "quickToggles"
import "../../components"

// Quick toggles row
ColumnLayout {
    id: root

    spacing: Motion.spacing.large

    // Toggle models
    readonly property list<QuickToggleModel> toggleModels: [
        QuickToggleModel {
            toggleId: "ethernet"
            name: QuickToggles.nameFor("ethernet")
            icon: "lan"
            toggled: EthernetStatus.connected
            available: EthernetStatus.available
            mainAction: () => EthernetStatus.openSettings()
        },
        QuickToggleModel {
            toggleId: "bluetooth"
            name: QuickToggles.nameFor("bluetooth")
            icon: BluetoothStatus.connected ? "bluetooth_connected" : (BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled")
            toggled: BluetoothStatus.enabled
            available: BluetoothStatus.available
            mainAction: () => BluetoothStatus.toggle()
            altAction: () => SidebarDialogState.openBluetooth()
        },
        QuickToggleModel {
            toggleId: "volume"
            name: QuickToggles.nameFor("volume")
            icon: Audio.muted ? "volume_off" : "volume_up"
            toggled: !Audio.muted
            mainAction: () => Audio.toggleMute()
            altAction: () => SidebarDialogState.openVolume()
        },
        QuickToggleModel {
            toggleId: "mic"
            name: QuickToggles.nameFor("mic")
            icon: Audio.micMuted ? "mic_off" : "mic"
            toggled: !Audio.micMuted
            mainAction: () => Audio.toggleMicMute()
            altAction: () => SidebarDialogState.openVolume()
        },
        QuickToggleModel {
            toggleId: "nightlight"
            name: QuickToggles.nameFor("nightlight")
            icon: "bedtime"
            toggled: NightLightState.enabled
            mainAction: () => NightLightState.toggle()
        },
        QuickToggleModel {
            toggleId: "dnd"
            name: QuickToggles.nameFor("dnd")
            icon: DndState.enabled ? "notifications_off" : "notifications"
            toggled: DndState.enabled
            mainAction: () => DndState.toggle()
        },
        QuickToggleModel {
            toggleId: "recording"
            name: QuickToggles.nameFor("recording")
            icon: "screen_record"
            toggled: ScreenRecorderCardState.enabled
            mainAction: () => ScreenRecorderCardState.toggle()
        },
        QuickToggleModel {
            toggleId: "keepawake"
            name: QuickToggles.nameFor("keepawake")
            icon: "coffee"
            toggled: KeepAwakeCardState.enabled
            mainAction: () => KeepAwakeCardState.toggle()
        },
        QuickToggleModel {
            toggleId: "gamemode"
            name: QuickToggles.nameFor("gamemode")
            icon: "sports_esports"
            toggled: GameModeState.enabled
            mainAction: () => GameModeState.toggle()
        }
    ]

    function modelFor(toggleId) {
        return root.toggleModels.find(t => t.toggleId === toggleId);
    }

    StyledText {
        text: "Quick Toggles"
        font.pixelSize: Motion.fontSize.title
        font.bold: true
    }

    // Visible toggles
    Flow {
        id: togglesFlow

        Layout.fillWidth: true

        readonly property int minSpacing: 8
        readonly property int cellWidth: 40 // small TogglePill
        readonly property bool allSmall: QuickToggles.orderedVisible.every(e => e.size === "small")
        // Per-row count
        readonly property int perRow: Math.min(QuickToggles.orderedVisible.length, Math.max(1, Math.floor((width + minSpacing) / (cellWidth + minSpacing))))

        spacing: allSmall && perRow > 1 ? Math.max(minSpacing, (width - perRow * cellWidth) / (perRow - 1)) : minSpacing

        Repeater {
            model: QuickToggles.orderedVisible

            TogglePill {
                id: pill

                required property var modelData

                readonly property QuickToggleModel toggleModel: root.modelFor(modelData.type)

                iconName: pill.toggleModel.icon
                active: pill.toggleModel.toggled
                enabled: pill.toggleModel.available
                large: pill.modelData.size === "large"
                label: pill.toggleModel.name
                onClicked: pill.toggleModel.mainAction()
                onAltClicked: if (pill.toggleModel.altAction) pill.toggleModel.altAction()
            }
        }
    }
}
