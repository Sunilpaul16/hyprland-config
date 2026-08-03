import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"
import "../../components"

// Workspace overview content (horizontal card row)
Item {
    id: root

    required property var screen
    required property bool active

    readonly property var allWorkspaces: Hyprland.workspaces.values
    readonly property int maxSlots: 20

    // Real workspaces plus one trailing empty slot, clamped to maxSlots against the Hyprland sentinel-id spike during hyprlock transitions
    readonly property var displaySlots: {
        const usedIds = root.allWorkspaces.map(ws => ws.id).filter(id => id > 0 && id <= root.maxSlots);
        const highestOccupied = Math.max(0, ...usedIds);
        const maxId = Math.min(highestOccupied + 1, root.maxSlots);
        const slots = [];
        for (let id = 1; id <= maxId; id++)
            slots.push(root.allWorkspaces.find(ws => ws.id === id) ?? { id, isPlaceholder: true });
        return slots;
    }

    // Card sizing
    readonly property int cardHeight: 200
    readonly property int cardSpacing: 16

    // Mirrors WorkspaceCard's own width calc so the row's natural width matches what renders, rotated monitors' swapped aspect included
    function slotCardWidth(slot) {
        const mon = (slot.isPlaceholder ? null : slot.monitor) ?? Hyprland.monitorFor(root.screen);
        const transform = mon?.lastIpcObject?.transform ?? 0;
        const rotated = transform % 2 === 1;
        const logicalWidth = mon ? (rotated ? mon.height : mon.width) : 16;
        const logicalHeight = mon ? (rotated ? mon.width : mon.height) : 9;
        return root.cardHeight * (logicalWidth / logicalHeight);
    }

    readonly property real naturalWidth: displaySlots.reduce((sum, slot) => sum + root.slotCardWidth(slot), 0) + Math.max(0, displaySlots.length - 1) * cardSpacing

    implicitWidth: Math.min(naturalWidth, (root.screen?.width ?? 1280) * 0.85)
    implicitHeight: cardHeight + 28
    width: implicitWidth
    height: implicitHeight

    // Drag-to-move session, shared by every WorkspaceCard/thumbnail in this row
    property bool dragActive: false
    property string dragAddress: ""
    property int dragSourceWorkspace: -1
    property string dragIconName: ""
    property int dragTargetWorkspace: -1

    function beginDrag(item, mouse, address, sourceWorkspaceId, iconName) {
        root.dragAddress = address;
        root.dragSourceWorkspace = sourceWorkspaceId;
        root.dragIconName = iconName;
        root.dragActive = true;
        root.updateDragPosition(item, mouse);
    }

    function updateDragPosition(item, mouse) {
        const pos = item.mapToItem(root, mouse.x, mouse.y);
        dragProxy.x = pos.x - dragProxy.width / 2;
        dragProxy.y = pos.y - dragProxy.height / 2;
    }

    function releaseDrag() {
        root.dragTargetWorkspace = -1;
        dragProxy.Drag.drop();
        if (root.dragTargetWorkspace > 0 && root.dragTargetWorkspace !== root.dragSourceWorkspace)
            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${root.dragTargetWorkspace}, follow = false, window = "address:${root.dragAddress}" })`);
        root.dragActive = false;
        root.dragAddress = "";
        root.dragSourceWorkspace = -1;
        root.dragIconName = "";
        root.dragTargetWorkspace = -1;
    }

    StyledText {
        anchors.bottom: list.top
        anchors.bottomMargin: Motion.spacing.normal
        anchors.left: list.left
        text: "Workspaces"
        font.pixelSize: Motion.fontSize.title
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
            overviewContent: root
        }
    }

    // Drag-to-move proxy — lives outside the ListView's clip so it isn't cut off crossing card boundaries
    Rectangle {
        id: dragProxy
        visible: root.dragActive
        z: 100
        width: 48
        height: 48
        radius: Motion.rounding.item
        color: Colors.panel
        border.width: 2
        border.color: Colors.primary

        Drag.active: root.dragActive
        Drag.keys: ["overview-window"]

        Image {
            anchors.centerIn: parent
            visible: root.dragIconName !== ""
            source: root.dragIconName ? Quickshell.iconPath(root.dragIconName, "") : ""
            sourceSize.width: 28
            sourceSize.height: 28
            smooth: true
        }
    }
}
