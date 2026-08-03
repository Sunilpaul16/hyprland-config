pragma Singleton
import QtQuick
import Quickshell

// Tray menu state
Singleton {
    id: root

    property bool open: false
    // Pinned monitor
    property string ownerScreen: ""
    property var targetItem: null
    // Anchor X
    property real anchorX: 0

    readonly property var entries: opener.children ? opener.children.values : []

    // Menu opener
    QsMenuOpener {
        id: opener
        menu: root.open && root.targetItem ? (root.targetItem.menu ?? null) : null
    }

    // Open/close controls
    function showAt(item: var, x: real): void {
        ScreenOwner.claim(root);
        root.targetItem = item;
        if (!isNaN(x))
            root.anchorX = x;
        root.open = true;
    }

    function close(): void {
        root.open = false;
    }
}
