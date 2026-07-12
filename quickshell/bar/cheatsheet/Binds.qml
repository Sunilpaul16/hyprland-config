pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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

    // Fetch binds from hyprctl
    Process {
        id: getBinds
        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.binds = JSON.parse(text);
                } catch (e) {
                    console.error("[Cheatsheet Binds] failed to parse hyprctl binds -j:", e);
                }
            }
        }
    }
}
