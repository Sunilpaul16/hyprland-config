import QtQuick
import QtQuick.Layouts
import "../../services"
import "quickToggles"

// Quick toggles row
ColumnLayout {
    id: root

    spacing: 12

    property bool editMode: false

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

        Text {
            text: "Quick Toggles"
            color: Colors.text
            font.pixelSize: 15
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        // Edit mode toggle
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 8
            color: root.editMode ? Colors.primary : (editHover.containsMouse ? Colors.surface : "transparent")

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            MaterialIcon {
                anchors.centerIn: parent
                text: root.editMode ? "check" : "edit"
                color: root.editMode ? Colors.background : Colors.text
                font.pixelSize: 15
            }

            MouseArea {
                id: editHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.editMode = !root.editMode
            }
        }
    }

    // Visible toggles — wraps to fit the card's width
    Flow {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: root.orderedVisible

            ToggleSlot {
                required property var modelData
                required property int index

                toggleModel: root.modelFor(modelData.type)
                size: modelData.size
                editMode: root.editMode
                isFirst: index === 0
                isLast: index === root.orderedVisible.length - 1
            }
        }
    }

    // Hidden/unused toggles — edit mode only, tap "+" to bring one back
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.editMode && root.hiddenModels.length > 0
        spacing: 6

        Text {
            text: "Hidden"
            color: Colors.textMuted
            font.pixelSize: 11
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.hiddenModels

                Item {
                    id: hiddenSlot
                    required property QuickToggleModel modelData

                    implicitWidth: 40
                    implicitHeight: 40

                    TogglePill {
                        anchors.fill: parent
                        iconName: hiddenSlot.modelData.icon
                        active: false
                        enabled: false
                        opacity: 0.5
                    }

                    // Add-back badge
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        anchors { top: parent.top; right: parent.right; margins: -2 }
                        color: Colors.primary
                        border.color: Colors.surface
                        border.width: 1.5

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "add"
                            color: Colors.background
                            font.pixelSize: 9
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addToggle(hiddenSlot.modelData.toggleId)
                        }
                    }
                }
            }
        }
    }

    // A single visible toggle: the pill, plus edit-mode hide/move/resize controls
    component ToggleSlot: Item {
        id: slot

        required property QuickToggleModel toggleModel
        required property string size // "small" | "large"
        property bool editMode: false
        property bool isFirst: false
        property bool isLast: false

        readonly property bool large: slot.size === "large"

        implicitWidth: pill.implicitWidth
        implicitHeight: 40

        TogglePill {
            id: pill
            anchors.fill: parent
            iconName: slot.toggleModel.icon
            active: slot.toggleModel.toggled
            enabled: slot.toggleModel.available && !slot.editMode
            large: slot.large
            label: slot.toggleModel.name
            onClicked: slot.toggleModel.mainAction()
            onAltClicked: if (slot.toggleModel.altAction) slot.toggleModel.altAction()
        }

        // Edit-mode outline + tap-to-resize
        MouseArea {
            anchors.fill: parent
            enabled: slot.editMode
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycleSize(slot.toggleModel.toggleId)

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                border.width: 1
                border.color: Colors.outline
            }
        }

        // Hide badge
        Rectangle {
            visible: slot.editMode
            width: 14
            height: 14
            radius: 7
            anchors { top: parent.top; right: parent.right; margins: -2 }
            color: Colors.outline
            border.color: Colors.surface
            border.width: 1.5

            MaterialIcon {
                anchors.centerIn: parent
                text: "close"
                color: Colors.background
                font.pixelSize: 9
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeToggle(slot.toggleModel.toggleId)
            }
        }

        // Move earlier badge
        Rectangle {
            visible: slot.editMode && !slot.isFirst
            width: 14
            height: 14
            radius: 7
            anchors { bottom: parent.bottom; left: parent.left; margins: -2 }
            color: Colors.surface
            border.color: Colors.outline
            border.width: 1

            MaterialIcon {
                anchors.centerIn: parent
                text: "chevron_left"
                color: Colors.text
                font.pixelSize: 9
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.moveToggle(slot.toggleModel.toggleId, -1)
            }
        }

        // Move later badge
        Rectangle {
            visible: slot.editMode && !slot.isLast
            width: 14
            height: 14
            radius: 7
            anchors { bottom: parent.bottom; right: parent.right; margins: -2 }
            color: Colors.surface
            border.color: Colors.outline
            border.width: 1

            MaterialIcon {
                anchors.centerIn: parent
                text: "chevron_right"
                color: Colors.text
                font.pixelSize: 9
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.moveToggle(slot.toggleModel.toggleId, 1)
            }
        }
    }
}
