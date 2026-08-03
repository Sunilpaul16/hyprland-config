pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Static preset palettes
Singleton {
    id: root

    // [{ id, scheme, flavour, modes }]
    property var list: []
    property bool available: true
    // Loaded preset roles
    property var colours: ({})

    property string pendingId: ""

    signal presetLoaded(string id)

    function loadPreset(id: string, mode: string): void {
        root.pendingId = id;
        readProc.command = [Directories.presetHelper, "matugen", id, mode];
        readProc.running = true;
    }

    // Single list pass
    Process {
        id: listProc

        running: true
        command: [Directories.presetHelper, "listall", Theme.mode === "light" ? "light" : "dark"]

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
                    const idParts = parts[0].split("/");
                    rows.push({
                        id: parts[0],
                        scheme: idParts[0],
                        flavour: idParts[1],
                        modes: parts[1] ? parts[1].split(" ") : [],
                        surface: "#" + parts[2],
                        primary: "#" + parts[3],
                        outline: "#" + parts[4]
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
