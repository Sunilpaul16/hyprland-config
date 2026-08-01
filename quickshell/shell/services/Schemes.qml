pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Static preset palettes from matugen/schemes/, via
// scripts/lib/preset-palette.py. Listing is one shot; an individual preset
// is read on demand for swatches and preview
Singleton {
    id: root

    // [{ id, scheme, flavour, modes }]
    property var list: []
    property bool available: true
    // roleName -> "#rrggbb" for the most recently loaded preset
    property var colours: ({})

    property string pendingId: ""

    signal presetLoaded(string id)

    function loadPreset(id: string, mode: string): void {
        root.pendingId = id;
        readProc.command = [Directories.presetHelper, "matugen", id, mode];
        readProc.running = true;
    }

    Process {
        id: listProc

        running: true
        command: [Directories.presetHelper, "list"]

        onExited: exitCode => {
            if (exitCode !== 0)
                root.available = false;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const parts = line.split("\t");
                    const id = parts[0];
                    const modes = parts[1];
                    const idParts = id.split("/");
                    rows.push({
                        id: id,
                        scheme: idParts[0],
                        flavour: idParts[1],
                        modes: modes ? modes.split(" ") : []
                    });
                }
                root.list = rows;
                root.available = rows.length > 0;
            }
        }
    }

    Process {
        id: readProc

        stdout: StdioCollector {
            onStreamFinished: {
                let json;
                try {
                    json = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const flat = {};
                for (const role in json.colors)
                    flat[role] = json.colors[role].default.color;
                root.colours = flat;
                root.presetLoaded(root.pendingId);
            }
        }
    }
}
