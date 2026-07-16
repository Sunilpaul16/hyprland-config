pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Local recordings list singleton
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Videos"
    property list<var> entries: [] // {name, path, mtimeMs}, newest first

    function refresh(): void {
        scanProc.running = true;
    }

    function deleteEntry(path: string): void {
        const proc = deleteComponent.createObject(root, { path });
        proc.running = true;
    }

    // "Recording_2026-07-16_01.26.03.mp4" -> "Jul 16, 2026 - 1:26 AM"
    function displayName(name: string): string {
        const m = name.match(/^Recording_(\d{4})-(\d{2})-(\d{2})_(\d{2})\.(\d{2})\.(\d{2})\.mp4$/);
        if (!m)
            return name;
        const [, y, mo, d, h, mi, s] = m.map(Number);
        const date = new Date(y, mo - 1, d, h, mi, s);
        return Qt.formatDateTime(date, "MMM d, yyyy — h:mm AP");
    }

    Component.onCompleted: root.refresh()

    // Scan for recordings, newest first
    Process {
        id: scanProc
        command: ["find", root.dir, "-maxdepth", "1", "-type", "f", "-iname", "Recording_*.mp4", "-printf", "%T@ %f\n"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0);
                root.entries = lines.map(line => {
                    const idx = line.indexOf(" ");
                    const mtimeMs = parseFloat(line.slice(0, idx)) * 1000;
                    const name = line.slice(idx + 1);
                    return { name, path: `${root.dir}/${name}`, mtimeMs };
                }).sort((a, b) => b.mtimeMs - a.mtimeMs);
            }
        }
    }

    // Delete-recording process factory
    Component {
        id: deleteComponent

        Process {
            property string path
            command: ["rm", "-f", path]
            onExited: {
                root.refresh();
                destroy();
            }
        }
    }
}
