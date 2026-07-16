import QtQuick
import Quickshell
import "../../services"

// Session/power actions row
Item {
    id: root

    property bool activeOverlay: false
    property string confirmingId: ""

    // Reset any in-progress confirm when the overlay closes
    onActiveOverlayChanged: if (!activeOverlay) root.confirmingId = ""

    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "\u{1F512}", confirm: false, command: ["hyprlock"] },
        { id: "logout", label: "Logout", icon: "\u{1F6AA}", confirm: true, command: ["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
        { id: "reboot", label: "Reboot", icon: "\u{1F501}", confirm: true, command: ["systemctl", "reboot"] },
        { id: "shutdown", label: "Shutdown", icon: "\u{23FB}", confirm: true, command: ["systemctl", "poweroff"] }
    ]

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Execute / confirm-gate actions
    function runAction(action): void {
        Quickshell.execDetached(action.command);
        SessionState.open = false;
    }

    function activate(action): void {
        if (action.confirm)
            root.confirmingId = action.id;
        else
            root.runAction(action);
    }

    Row {
        id: row
        spacing: 16

        Repeater {
            model: root.actions

            SessionActionButton {
                required property var modelData

                action: modelData
                confirming: root.confirmingId === modelData.id
                onActivate: root.activate(modelData)
                onConfirm: root.runAction(modelData)
                onCancel: root.confirmingId = ""
            }
        }
    }
}
