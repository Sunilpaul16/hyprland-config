pragma Singleton
import QtQuick
import Quickshell

// Tray context-menu state: which item's menu is open, and where to
// anchor it (scene coords, shared between the Bar and TrayMenu windows
// since both windows align to the same screen's top-left origin).
// The QsMenuOpener lives here (not per-monitor) so opening a menu only
// triggers one DBusMenu layout fetch, not one per monitor overlay.
Singleton {
    id: root

    property bool open: false
    property var targetItem: null
    property real anchorX: 0
    property real anchorY: 0

    readonly property var entries: opener.children ? opener.children.values : []

    // SystemTrayItem.menu is a qs::dbus::dbusmenu::DBusMenuHandle — a C++
    // subclass of QsMenuHandle that isn't itself QML-registered, so QML
    // only sees it as the abstract QsMenuHandle base (no visible `.menu`
    // property, just a virtual method QsMenuOpener calls internally).
    // Pass item.menu straight through — do NOT try item.menu.menu.
    QsMenuOpener {
        id: opener
        menu: root.open && root.targetItem ? (root.targetItem.menu ?? null) : null
    }

    function showAt(item: var, x: real, y: real): void {
        root.targetItem = item;
        root.anchorX = x;
        root.anchorY = y;
        root.open = true;
    }

    function close(): void {
        root.open = false;
    }
}
