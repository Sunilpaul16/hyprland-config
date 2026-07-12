pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "launcher/fuzzysort.js" as Fuzzy


Singleton {
    id: root

    readonly property string cliphistBinary: "cliphist"
    property list<string> entries: []
    function entryIsImage(entry) {
        return /^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry);
    }

    function entryId(entry) {
        return entry.match(/^(\d+)\t/)?.[1] ?? "";
    }
    readonly property string decodeDir: "/tmp/quickshell-bar-cliphist"
    function displayText(entry) {
        if (root.entryIsImage(entry)) {
            const dims = entry.match(/(\d+)x(\d+)/);
            const mime = entry.match(/\b(png|jpe?g|gif|bmp|webp|tiff?)\b/i)?.[1] ?? "image";
            return dims ? `[image ${dims[1]}x${dims[2]} ${mime}]` : "[image]";
        }
        return entry.replace(/^\d+\t/, "");
    }

    function query(search: string): var {
        const rows = root.entries.map(entry => ({
            entry,
            text: root.displayText(entry),
            isImage: root.entryIsImage(entry)
        }));
        const trimmed = search.trim();
        if (!trimmed)
            return rows;
        return Fuzzy.go(trimmed, rows, { key: "text", all: true }).map(r => r.obj);
    }

    function refresh() {
        listProc.buffer = [];
        listProc.running = true;
    }

    function copy(entry) {
        copyProc.pendingEntry = entry;
        copyProc.stdinEnabled = true;
        copyProc.running = true;
    }

    function deleteEntry(entry) {
        deleteProc.pendingEntry = entry;
        deleteProc.stdinEnabled = true;
        deleteProc.running = true;
    }

    function wipe() {
        wipeProc.running = true;
    }

    Component.onCompleted: {
        root.refresh();
        wipeDecodeDirProc.running = true;
    }

    Process {
        id: wipeDecodeDirProc
        command: ["bash", "-c", `rm -rf '${root.decodeDir}'; mkdir -p '${root.decodeDir}'`]
    }

    Process {
        id: listProc
        property list<string> buffer: []
        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: line => listProc.buffer.push(line)
        }

        onExited: exitCode => {
            if (exitCode === 0)
                root.entries = listProc.buffer;
            else
                console.error("[Cliphist] `cliphist list` failed with code", exitCode);
        }
    }

    Process {
        id: copyProc
        property string pendingEntry: ""
        command: ["bash", "-c", `${root.cliphistBinary} decode | wl-copy`]
        onStarted: {
            copyProc.write(copyProc.pendingEntry + "\n");
            copyProc.stdinEnabled = false;
        }
    }

    Process {
        id: deleteProc
        property string pendingEntry: ""
        command: [root.cliphistBinary, "delete"]
        onStarted: {
            deleteProc.write(deleteProc.pendingEntry + "\n");
            deleteProc.stdinEnabled = false;
        }
        onExited: root.refresh()
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: root.refresh()
    }
}
