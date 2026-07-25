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
    property real anchorX: 0
    property real anchorY: 0

    readonly property var entries: opener.children ? opener.children.values : []

    // Menu opener for the target tray item
    QsMenuOpener {
        id: opener
        menu: root.open && root.targetItem ? (root.targetItem.menu ?? null) : null
    }

    // Open/close controls
    function showAt(item: var, x: real, y: real): void {
        ScreenOwner.claim(root);
        root.targetItem = item;
        root.anchorX = x;
        root.anchorY = y;
        root.open = true;
    }

    function close(): void {
        root.open = false;
    }
}
