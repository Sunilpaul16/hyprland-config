import QtQuick
import QtQuick.Layouts
import "../../services"
import "quickToggles"
import "../../components"

// Quick toggles row
ColumnLayout {
    id: root

    spacing: 12

    // Feature/state only — visibility/order/size live in Persistent.quickToggleLayout (comparison.md #24)
    readonly property list<QuickToggleModel> toggleModels: [
        QuickToggleModel {
            toggleId: "ethernet"
            name: "Ethernet"
            icon: "lan"
            toggled: EthernetStatus.connected
            available: EthernetStatus.available
            mainAction: () => EthernetStatus.openSettings()
        },
        QuickToggleModel {
            toggleId: "bluetooth"
            name: "Bluetooth"
            icon: BluetoothStatus.connected ? "bluetooth_connected" : (BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled")
            toggled: BluetoothStatus.enabled
            available: BluetoothStatus.available
            mainAction: () => BluetoothStatus.toggle()
            altAction: () => SidebarDialogState.openBluetooth()
        },
        QuickToggleModel {
            toggleId: "volume"
            name: "Volume"
            icon: Audio.muted ? "volume_off" : "volume_up"
            toggled: !Audio.muted
            mainAction: () => Audio.toggleMute()
            altAction: () => SidebarDialogState.openVolume()
        },
        QuickToggleModel {
            toggleId: "mic"
            name: "Microphone"
            icon: Audio.micMuted ? "mic_off" : "mic"
            toggled: !Audio.micMuted
            mainAction: () => Audio.toggleMicMute()
            altAction: () => SidebarDialogState.openVolume()
        },
        QuickToggleModel {
            toggleId: "nightlight"
            name: "Night Light"
            icon: "bedtime"
            toggled: NightLightState.enabled
            mainAction: () => NightLightState.toggle()
        },
        QuickToggleModel {
            toggleId: "dnd"
            name: "Do Not Disturb"
            icon: DndState.enabled ? "notifications_off" : "notifications"
            toggled: DndState.enabled
            mainAction: () => DndState.toggle()
        },
        QuickToggleModel {
            toggleId: "recording"
            name: "Screen Recorder"
            icon: "screen_record"
            toggled: ScreenRecorderCardState.enabled
            mainAction: () => ScreenRecorderCardState.toggle()
        },
        QuickToggleModel {
            toggleId: "keepawake"
            name: "Keep Awake"
            icon: "coffee"
            toggled: KeepAwakeCardState.enabled
            mainAction: () => KeepAwakeCardState.toggle()
        },
        QuickToggleModel {
            toggleId: "gamemode"
            name: "Game Mode"
            icon: "sports_esports"
            toggled: GameModeState.enabled
            mainAction: () => GameModeState.toggle()
        }
    ]

    // Fallback order before the user has ever hidden/reordered/resized anything
    readonly property var defaultLayout: root.toggleModels.map(t => ({ type: t.toggleId, size: "small" }))

    // Reconciled against the live model list — a removed toggle's stale entry is silently dropped
    readonly property var orderedVisible: {
        const knownIds = root.toggleModels.map(t => t.toggleId);
        const source = Persistent.quickToggleLayout.length > 0 ? Persistent.quickToggleLayout : root.defaultLayout;
        return source.filter(entry => knownIds.indexOf(entry.type) !== -1);
    }

    // Exist but aren't in the visible layout — surfaced as an "add back" palette while editing
    readonly property var hiddenModels: {
        const visibleIds = root.orderedVisible.map(e => e.type);
        return root.toggleModels.filter(t => visibleIds.indexOf(t.toggleId) === -1);
    }

    function modelFor(toggleId) {
        return root.toggleModels.find(t => t.toggleId === toggleId);
    }

    // Layout mutations — each writes Persistent.quickToggleLayout
    function addToggle(toggleId) {
        const list = Persistent.quickToggleLayout.slice();
        list.push({ type: toggleId, size: "small" });
        Persistent.quickToggleLayout = list;
    }

    function removeToggle(toggleId) {
        Persistent.quickToggleLayout = root.orderedVisible.filter(e => e.type !== toggleId);
    }

    function moveToggle(toggleId, delta) {
        const list = root.orderedVisible.slice();
        const idx = list.findIndex(e => e.type === toggleId);
        const newIdx = idx + delta;
        if (idx === -1 || newIdx < 0 || newIdx >= list.length)
            return;
        const entry = list.splice(idx, 1)[0];
        list.splice(newIdx, 0, entry);
        Persistent.quickToggleLayout = list;
    }

    function cycleSize(toggleId) {
        const list = root.orderedVisible.slice();
        const idx = list.findIndex(e => e.type === toggleId);
        if (idx === -1)
            return;
        list[idx] = { type: toggleId, size: list[idx].size === "large" ? "small" : "large" };
        Persistent.quickToggleLayout = list;
    }

    // Header
    RowLayout {
        Layout.fillWidth: true

        StyledText {
            text: "Quick Toggles"
            font.pixelSize: 15
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        // Edit mode toggle
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: Motion.rounding.small
            color: SidebarRightState.quickTogglesEditMode ? Colors.primary : (editHover.containsMouse ? Colors.layer : "transparent")

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            MaterialIcon {
                anchors.centerIn: parent
                text: SidebarRightState.quickTogglesEditMode ? "check" : "edit"
                color: SidebarRightState.quickTogglesEditMode ? Colors.background : Colors.text
                font.pixelSize: 15
            }

            MouseArea {
                id: editHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SidebarRightState.quickTogglesEditMode = !SidebarRightState.quickTogglesEditMode
            }
        }
    }

    // Visible toggles — wraps to fit the card's width, with the leftover
    // width dealt into the gaps so the row has no ragged right edge.
    // Only exact while every toggle is the same width; a "large" one varies,
    // so that case keeps the plain minimum spacing.
    Flow {
        id: togglesFlow

        Layout.fillWidth: true

        readonly property int minSpacing: 8
        readonly property int cellWidth: 40 // small TogglePill
        readonly property bool allSmall: root.orderedVisible.every(e => e.size === "small")
        // Most that fit at minimum spacing, capped by how many there actually are
        readonly property int perRow: Math.min(root.orderedVisible.length, Math.max(1, Math.floor((width + minSpacing) / (cellWidth + minSpacing))))

        spacing: allSmall && perRow > 1 ? Math.max(minSpacing, (width - perRow * cellWidth) / (perRow - 1)) : minSpacing

        Repeater {
            model: root.orderedVisible

            QuickToggleSlot {
                required property var modelData
                required property int index

                toggleModel: root.modelFor(modelData.type)
                size: modelData.size
                editMode: SidebarRightState.quickTogglesEditMode
                isFirst: index === 0
                isLast: index === root.orderedVisible.length - 1

                onResizeRequested: root.cycleSize(modelData.type)
                onHideRequested: root.removeToggle(modelData.type)
                onMoveRequested: delta => root.moveToggle(modelData.type, delta)
            }
        }
    }

    QuickTogglesHiddenPanel {
        Layout.fillWidth: true
        visible: SidebarRightState.quickTogglesEditMode && root.hiddenModels.length > 0
        models: root.hiddenModels
        onAddRequested: toggleId => root.addToggle(toggleId)
    }
}
