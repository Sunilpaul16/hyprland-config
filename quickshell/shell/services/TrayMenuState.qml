pragma Singleton
import QtQuick
import QtQml.Models
import Quickshell

// Tray menu state
Singleton {
    id: root

    property bool open: false
    // Pinned monitor
    property string ownerScreen: ""
    property var currentMenu: null
    property var menuStack: []
    property string searchQuery: ""
    property bool ready: false
    // Anchor X
    property real anchorX: 0

    readonly property var entries: opener.children ? opener.children.values : []
    readonly property bool isConnectionsMenu: root.currentMenu
        && /^all connections$/i.test(String(root.currentMenu.text ?? "").trim())
    readonly property var filteredEntries: {
        const visibleEntries = root.entries.filter(entry =>
            entry.isSeparator
                || !(/^download\b/i.test(entry.text.trim())
                    && /\bnordvpn\b/i.test(entry.text)
                    && /\bapp(?:lication)?\b/i.test(entry.text)));
        const query = root.searchQuery.trim().toLowerCase();
        if (query.length === 0)
            return root.withCleanSeparators(visibleEntries);
        return visibleEntries.filter(entry => !entry.isSeparator
            && entry.text.toLowerCase().includes(query));
    }

    function withCleanSeparators(source: var): var {
        const cleaned = [];
        for (const entry of source) {
            if (entry.isSeparator && (cleaned.length === 0 || cleaned[cleaned.length - 1].isSeparator))
                continue;
            cleaned.push(entry);
        }
        if (cleaned.length > 0 && cleaned[cleaned.length - 1].isSeparator)
            cleaned.pop();
        return cleaned;
    }

    onEntriesChanged: {
        if (root.open && root.entries.length > 0)
            root.ready = true;
    }

    // Menu opener
    QsMenuOpener {
        id: opener
        menu: root.open ? root.currentMenu : null
    }

    // Keep every parent menu open while viewing one of its descendants. DBus
    // menus discard a submenu's objects when its opener is released.
    Instantiator {
        model: root.open ? root.menuStack : []

        delegate: QsMenuOpener {
            required property var modelData
            menu: modelData
        }
    }

    // Open/close controls
    function showAt(item: var, x: real): void {
        ScreenOwner.claim(root);
        root.currentMenu = item ? (item.menu ?? null) : null;
        root.menuStack = [];
        root.searchQuery = "";
        root.ready = false;
        if (!isNaN(x))
            root.anchorX = x;
        root.open = true;
        if (root.entries.length > 0)
            root.ready = true;
    }

    function openSubmenu(entry: var): void {
        if (!entry || !entry.hasChildren)
            return;
        root.searchQuery = "";
        root.menuStack = root.menuStack.concat([root.currentMenu]);
        // Let the parent retainer acquire its handle before the main opener
        // releases it, otherwise dynamic DBus submenu entries disappear.
        Qt.callLater(() => {
            if (root.open)
                root.currentMenu = entry;
        });
    }

    function goBack(): void {
        if (root.menuStack.length === 0)
            return;
        const previous = root.menuStack[root.menuStack.length - 1];
        root.searchQuery = "";
        // Let the main opener acquire the parent before its stack retainer is
        // removed, mirroring the safe handoff used when entering a submenu.
        root.currentMenu = previous;
        root.menuStack = root.menuStack.slice(0, -1);
    }

    function close(): void {
        root.open = false;
        root.menuStack = [];
        root.currentMenu = null;
        root.searchQuery = "";
        root.ready = false;
    }
}
