pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Local recordings list singleton
Singleton {
    id: root

    readonly property string dir: Directories.videosDir
    property list<var> entries: [] // {name, path, mtimeMs}, newest first

    function refresh(): void {
        scanProc.running = true;
    }

    function trashEntry(path: string): void {
        const proc = trashComponent.createObject(root, { path });
        proc.running = true;
    }

    // Display name, from mtime not the filename
    function displayName(entry): string {
        if (!entry?.mtimeMs)
            return entry?.name ?? "";
        return Qt.formatDateTime(new Date(entry.mtimeMs), "MMM d, yyyy — " + Time.clockFormat);
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

    // Move recordings to the desktop trash so an accidental deletion is recoverable.
    Component {
        id: trashComponent

        Process {
            property string path
            command: ["gio", "trash", path]
            onExited: exitCode => {
                root.refresh();
                if (exitCode !== 0)
                    Quickshell.execDetached(["notify-send", "Recording was not removed", "Could not move the recording to Trash"]);
                destroy();
            }
        }
    }
}
