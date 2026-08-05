pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Widget overlay state
Singleton {
    id: root

    property bool open: false
    // Pinned monitor
    property string ownerScreen: ""

    // Two-way, guarded
    onOwnerScreenChanged: {
        if (Persistent.overlayScreen !== root.ownerScreen)
            Persistent.overlayScreen = root.ownerScreen;
    }

    Connections {
        target: Persistent
        function onOverlayScreenChanged(): void {
            if (root.ownerScreen !== Persistent.overlayScreen)
                root.ownerScreen = Persistent.overlayScreen;
        }
    }

    signal requestCenter(string identifier)

    // Widget registry
    readonly property var widgets: [
        {
            identifier: "crosshair",
            icon: "point_scan",
            label: "Crosshair"
        },
        {
            identifier: "notes",
            icon: "note_stack",
            label: "Notes"
        }
    ]

    readonly property var entries: Persistent.overlayWidgets ?? ({})

    readonly property var openIds: {
        const out = [];
        for (const w of root.widgets)
            if (root.entries[w.identifier]?.open)
                out.push(w.identifier);
        return out;
    }

    readonly property bool hasPinned: {
        for (const id of root.openIds)
            if (root.entries[id]?.pinned)
                return true;
        return false;
    }

    function entry(id: string): var {
        return root.entries[id] ?? ({});
    }

    // Merge and persist
    function update(id: string, changes: var): void {
        const all = JSON.parse(JSON.stringify(root.entries));
        all[id] = Object.assign(all[id] ?? {}, changes);
        Persistent.overlayWidgets = all;
    }

    function toggle(): void {
        ScreenOwner.toggle(root);
    }

    function toggleWidget(id: string): void {
        root.update(id, {
            open: !root.entry(id).open
        });
    }

    function known(id: string): bool {
        return root.widgets.some(w => w.identifier === id);
    }

    // IPC handler
    IpcHandler {
        target: "overlay"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            ScreenOwner.claim(root);
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }

        function widget(id: string): string {
            if (!root.known(id))
                return `unknown widget: ${id}`;
            root.toggleWidget(id);
            return `${id} ${root.entry(id).open ? "opened" : "closed"}`;
        }

        function center(id: string): string {
            if (!root.known(id))
                return `unknown widget: ${id}`;
            root.requestCenter(id);
            return `${id} centered`;
        }
    }
}
