pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Per-wallpaper framing
Singleton {
    id: root

    readonly property real defaultOffset: 0.5
    property var offsets: ({})

    readonly property real current: root.offsetFor(Wallpapers.current)

    function offsetFor(path: string): real {
        if (!path)
            return root.defaultOffset;
        const v = root.offsets[path];
        return (typeof v === "number" && Number.isFinite(v)) ? v : root.defaultOffset;
    }

    function setFor(path: string, value: real): void {
        if (!path)
            return;
        const v = Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : root.defaultOffset;
        const next = Object.assign({}, root.offsets);
        next[path] = v;
        root.offsets = next;
        writeDebounce.restart();
        root.push(v);
    }

    // Flush pending write
    function flush(): void {
        writeDebounce.stop();
        file.setText(JSON.stringify(root.offsets, null, 2));
    }

    // Live mpv push
    function push(value: real): void {
        WallpaperMpv.command(["set_property", "video-align-x", value * 2 - 1]);
    }

    function parse(raw: string): void {
        try {
            const parsed = JSON.parse(raw);
            root.offsets = (parsed && typeof parsed === "object") ? parsed : ({});
        } catch (e) {
            root.offsets = ({});
        }
    }

    // State file
    FileView {
        id: file
        path: Directories.wallpaperFramingFile
        watchChanges: true
        printErrors: false
        blockWrites: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }

    // Debounced write
    Timer {
        id: writeDebounce
        interval: 300
        onTriggered: file.setText(JSON.stringify(root.offsets, null, 2))
    }

    IpcHandler {
        target: "framing"

        function get(): string {
            return String(root.current);
        }

        function set(value: string): string {
            const v = parseFloat(value);
            if (isNaN(v))
                return "invalid";
            root.setFor(Wallpapers.current, v);
            return String(root.offsetFor(Wallpapers.current));
        }

        function nudge(delta: string): string {
            const d = parseFloat(delta);
            if (isNaN(d))
                return "invalid";
            root.setFor(Wallpapers.current, root.current + d);
            return String(root.offsetFor(Wallpapers.current));
        }
    }
}
