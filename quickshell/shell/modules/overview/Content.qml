import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../services"

// Workspace overview content (horizontal card row)
Item {
    id: root

    required property var screen
    required property bool active

    readonly property var allWorkspaces: Hyprland.workspaces.values
    readonly property int minSlots: 4
    readonly property int maxSlots: 20

    // Build display slots (real + placeholder, clamped to maxSlots)
    readonly property var displaySlots: {
        const usedIds = root.allWorkspaces.map(ws => ws.id).filter(id => id > 0 && id <= root.maxSlots);
        const maxId = Math.max(root.minSlots, ...usedIds, 0);
        const slots = [];
        for (let id = 1; id <= maxId; id++)
            slots.push(root.allWorkspaces.find(ws => ws.id === id) ?? { id, isPlaceholder: true });
        return slots;
    }

    // Card sizing
    readonly property int cardHeight: 200
    readonly property int cardSpacing: 16

    readonly property real estimatedCardWidth: cardHeight * 16 / 9
    readonly property real naturalWidth: displaySlots.length * estimatedCardWidth + Math.max(0, displaySlots.length - 1) * cardSpacing

    implicitWidth: Math.min(naturalWidth, (root.screen?.width ?? 1280) * 0.85)
    implicitHeight: cardHeight + 28
    width: implicitWidth
    height: implicitHeight

    Text {
        anchors.bottom: list.top
        anchors.bottomMargin: 8
        anchors.left: list.left
        text: "Workspaces"
        color: Colors.text
        font.pixelSize: 15
        font.bold: true
    }

    // Workspace card row
    ListView {
        id: list
        anchors.top: parent.top
        anchors.topMargin: 28
        width: parent.width
        height: root.cardHeight
        orientation: ListView.Horizontal
        spacing: root.cardSpacing
        clip: true

        model: ScriptModel {
            values: root.displaySlots
        }

        delegate: WorkspaceCard {
            required property var modelData
            height: root.cardHeight
            screen: root.screen
            active: root.active
            slot: modelData
        }
    }
}
