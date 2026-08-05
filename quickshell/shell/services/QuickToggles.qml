pragma Singleton
import QtQuick
import Quickshell

// Quick toggle layout
Singleton {
    id: root

    // Toggle catalog
    readonly property var catalog: [
        { id: "ethernet", name: "Ethernet", icon: "lan" },
        { id: "bluetooth", name: "Bluetooth", icon: "bluetooth" },
        { id: "volume", name: "Volume", icon: "volume_up" },
        { id: "mic", name: "Microphone", icon: "mic" },
        { id: "nightlight", name: "Night Light", icon: "bedtime" },
        { id: "dnd", name: "Do Not Disturb", icon: "notifications" },
        { id: "recording", name: "Screen Recorder", icon: "screen_record" },
        { id: "keepawake", name: "Keep Awake", icon: "coffee" },
        { id: "gamemode", name: "Game Mode", icon: "sports_esports" }
    ]

    // Default layout
    readonly property var defaultLayout: root.catalog.map(t => ({ type: t.id, size: "small" }))

    // Reconciled visible
    readonly property var orderedVisible: {
        const knownIds = root.catalog.map(t => t.id);
        const source = Persistent.quickToggleLayout.length > 0 ? Persistent.quickToggleLayout : root.defaultLayout;
        return source.filter(entry => knownIds.indexOf(entry.type) !== -1);
    }

    // Hidden catalog entries
    readonly property var hidden: {
        const visibleIds = root.orderedVisible.map(e => e.type);
        return root.catalog.filter(t => visibleIds.indexOf(t.id) === -1);
    }

    function metaFor(toggleId: string): var {
        return root.catalog.find(t => t.id === toggleId) ?? null;
    }

    function nameFor(toggleId: string): string {
        return root.metaFor(toggleId)?.name ?? toggleId;
    }

    // Layout mutations
    function addToggle(toggleId: string): void {
        if (!root.metaFor(toggleId) || root.orderedVisible.some(e => e.type === toggleId))
            return;
        const list = root.orderedVisible.slice();
        list.push({ type: toggleId, size: "small" });
        Persistent.quickToggleLayout = list;
    }

    // Keeps one visible
    function removeToggle(toggleId: string): void {
        if (root.orderedVisible.length <= 1)
            return;
        Persistent.quickToggleLayout = root.orderedVisible.filter(e => e.type !== toggleId);
    }

    function moveToggle(toggleId: string, delta: int): void {
        const list = root.orderedVisible.slice();
        const idx = list.findIndex(e => e.type === toggleId);
        const newIdx = idx + delta;
        if (idx === -1 || newIdx < 0 || newIdx >= list.length)
            return;
        const entry = list.splice(idx, 1)[0];
        list.splice(newIdx, 0, entry);
        Persistent.quickToggleLayout = list;
    }

    // "small" | "large"
    function setSize(toggleId: string, size: string): void {
        const list = root.orderedVisible.slice();
        const idx = list.findIndex(e => e.type === toggleId);
        if (idx === -1)
            return;
        list[idx] = { type: toggleId, size: size };
        Persistent.quickToggleLayout = list;
    }
}
