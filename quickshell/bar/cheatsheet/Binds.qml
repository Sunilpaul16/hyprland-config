pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Parses `hyprctl binds -j` into cheatsheet rows. Run once when the overlay
// opens (see Connections below), not polled -- keybinds only change on a
// config reload, which isn't a normal-operation event worth watching for
// continuously (unlike Workspaces.qml's genuinely live Hyprland data).
//
// Every bind in ~/.config/hypr/keybinds.lua now carries a "Category: label"
// description (see the convention comment at that file's top). Two things
// happen here beyond a straight parse:
//   - category/label are split out of "Category: label" once per bind.
//   - binds that share an identical description are grouped; if that
//     group's keys are exactly a digit sequence (the workspace switch/
//     move-to loop's "<N>" placeholder description), it collapses into one
//     row spanning the key range. Any other same-description group (e.g.
//     the two play/pause keys) is left as separate individual rows --
//     collapsing non-numeric keys into a "range" wouldn't mean anything.
Singleton {
    id: root

    property var binds: []

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

    // Category display order -- known ones first (roughly most-used to
    // least), anything unexpected falls back to alphabetical after them.
    readonly property var categoryOrder: ["Window", "Workspace", "App", "Launcher", "Screenshot", "Record", "Media", "System", "Screen"]

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
