pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Keybind data singleton
Singleton {
    id: root

    property var binds: []

    // Group binds by description into display rows
    readonly property var rows: {
        const order = [];
        const groups = new Map();
        for (const b of root.binds) {
            if (!groups.has(b.description)) {
                groups.set(b.description, []);
                order.push(b.description);
            }
            groups.get(b.description).push(b);
        }

        const result = [];
        for (const desc of order) {
            const group = groups.get(desc);
            const colonIdx = desc.indexOf(":");
            const category = colonIdx >= 0 ? desc.substring(0, colonIdx).trim() : "Other";
            const label = colonIdx >= 0 ? desc.substring(colonIdx + 1).trim() : desc.trim();

            const allDigits = group.length > 1 && group.every(b => /^[0-9]$/.test(b.key));
            if (allDigits) {
                const sorted = [...group].sort((a, b) => {
                    const na = a.key === "0" ? 10 : parseInt(a.key);
                    const nb = b.key === "0" ? 10 : parseInt(b.key);
                    return na - nb;
                });
                result.push({
                    category,
                    label: label.replace("<N>", "1-0"),
                    modmask: sorted[0].modmask,
                    keys: [sorted[0].key, sorted[sorted.length - 1].key],
                    isRange: true
                });
            } else {
                for (const b of group) {
                    result.push({ category, label, modmask: b.modmask, keys: [b.key], isRange: false });
                }
            }
        }
        return result;
    }

    readonly property var categoryOrder: ["Window", "Workspace", "App", "Launcher", "Screenshot", "Record", "Media", "System", "Screen"]

    // Ordered category list
    readonly property var categories: {
        const seen = new Set(root.rows.map(r => r.category));
        const known = root.categoryOrder.filter(c => seen.has(c));
        const rest = [...seen].filter(c => !root.categoryOrder.includes(c)).sort();
        return [...known, ...rest];
    }

    function rowsFor(category) {
        return root.rows.filter(r => r.category === category);
    }

    function refresh() {
        getBinds.running = true;
    }

    // Re-fetch whenever Hyprland's config is reloaded, so the cheatsheet
    // is never stale after `hyprctl reload`
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.refresh();
        }
    }

    // Parses `hyprctl binds`' plain-text form (blank-line-separated records, a type line then tab-indented `field: value`) — split on the FIRST colon only, since descriptions carry one
    function parseBinds(text: string): var {
        const out = [];
        for (const block of text.split("\n\n")) {
            const lines = block.split("\n").filter(l => l.trim().length > 0);
            if (lines.length < 2)
                continue;

            const rec = {};
            for (const line of lines.slice(1)) {
                const idx = line.indexOf(":");
                if (idx < 0)
                    continue;
                rec[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
            }

            if (!rec.key)
                continue;
            rec.modmask = parseInt(rec.modmask) || 0;
            out.push(rec);
        }
        return out;
    }

    // Fetch binds from hyprctl
    // Deliberately NOT `-j`: Hyprland 0.56.0's JSON serializer shifts values against their keys and leaves strings unquoted, so it doesn't parse at all
    Process {
        id: getBinds
        command: ["hyprctl", "binds"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root.parseBinds(text);
                if (parsed.length === 0)
                    console.error("[Cheatsheet Binds] hyprctl binds returned no parsable binds");
                root.binds = parsed;
            }
        }
    }
}
