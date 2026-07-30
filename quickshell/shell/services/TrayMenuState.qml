pragma Singleton
import QtQuick
import Quickshell

// Tray menu open/close + entries state
Singleton {
    id: root

    property bool open: false
    // Monitor this panel is pinned to while open
    property string ownerScreen: ""
    property var targetItem: null
    // Left edge of the tray icon, in bar-window coordinates — the menu
    // hangs off the bar, so it needs no vertical anchor
    property real anchorX: 0

    readonly property var entries: opener.children ? opener.children.values : []

    // Menu opener for the target tray item
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
