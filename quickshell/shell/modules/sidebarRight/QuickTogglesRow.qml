import QtQuick
import QtQuick.Layouts
import "../../services"

// Quick toggles row
ColumnLayout {
    id: root

    spacing: 12

    property bool editMode: false
    // Placeholder — not wired to anything yet
    property bool gamingModeActive: false

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

    // Icon flow — wraps to fit the card's width; editing also reveals any
    // toggles the user has hidden, so more rows may appear
    Flow {
        Layout.fillWidth: true
        spacing: 8

        // Ethernet (opens NetworkManager's connection editor)
        ToggleSlot {
            toggleId: "ethernet"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: "lan"
                active: EthernetStatus.connected
                enabled: EthernetStatus.available
                onClicked: EthernetStatus.openSettings()
            }
        }

        // Bluetooth
        ToggleSlot {
            toggleId: "bluetooth"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: BluetoothStatus.connected ? "bluetooth_connected" : (BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled")
                active: BluetoothStatus.enabled
                enabled: BluetoothStatus.available
                onClicked: BluetoothStatus.toggle()
            }
        }

        // Mic
        ToggleSlot {
            toggleId: "mic"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: Audio.micMuted ? "mic_off" : "mic"
                active: !Audio.micMuted
                onClicked: Audio.toggleMicMute()
            }
        }

        // Settings (placeholder)
        ToggleSlot {
            toggleId: "settings"
            editMode: root.editMode

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Colors.background

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "settings"
                    color: Colors.text
                    font.pixelSize: 20
                }
            }
        }

        // Night light
        ToggleSlot {
            toggleId: "nightlight"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: "bedtime"
                active: NightLightState.enabled
                onClicked: NightLightState.toggle()
            }
        }

        // Do not disturb
        ToggleSlot {
            toggleId: "dnd"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: DndState.enabled ? "notifications_off" : "notifications"
                active: DndState.enabled
                onClicked: DndState.toggle()
            }
        }

        // Screen Recorder card visibility
        ToggleSlot {
            toggleId: "recording"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: "screen_record"
                active: ScreenRecorderCardState.enabled
                onClicked: ScreenRecorderCardState.toggle()
            }
        }

        // Keep Awake card visibility
        ToggleSlot {
            toggleId: "keepawake"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: "coffee"
                active: KeepAwakeCardState.enabled
                onClicked: KeepAwakeCardState.toggle()
            }
        }

        // Gaming mode (placeholder)
        ToggleSlot {
            toggleId: "gaming"
            editMode: root.editMode

            TogglePill {
                anchors.fill: parent
                iconName: "sports_esports"
                active: root.gamingModeActive
                onClicked: root.gamingModeActive = !root.gamingModeActive
            }
        }
    }

    // Wraps a toggle pill: hidden outside edit mode once the user hides
    // it, and becomes a show/hide switch while editing (badge marks state)
    component ToggleSlot: Item {
        id: slot

        required property string toggleId
        property bool editMode: false
        default property alias content: contentItem.children

        readonly property bool hidden: Persistent.hiddenQuickToggles.indexOf(toggleId) !== -1
        visible: slot.editMode || !slot.hidden

        implicitWidth: 40
        implicitHeight: 40

        Item {
            id: contentItem
            anchors.fill: parent
            opacity: slot.editMode && slot.hidden ? 0.35 : 1
        }

        MouseArea {
            anchors.fill: parent
            enabled: slot.editMode
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const ids = Persistent.hiddenQuickToggles.slice();
                const idx = ids.indexOf(slot.toggleId);
                if (idx !== -1)
                    ids.splice(idx, 1);
                else
                    ids.push(slot.toggleId);
                Persistent.hiddenQuickToggles = ids;
            }
        }

        // Show/hide badge
        Rectangle {
            visible: slot.editMode
            width: 14
            height: 14
            radius: 7
            anchors { top: parent.top; right: parent.right; margins: -2 }
            color: slot.hidden ? Colors.outline : Colors.primary
            border.color: Colors.surface
            border.width: 1.5

            MaterialIcon {
                anchors.centerIn: parent
                text: slot.hidden ? "close" : "check"
                color: Colors.background
                font.pixelSize: 9
            }
        }
    }
}
