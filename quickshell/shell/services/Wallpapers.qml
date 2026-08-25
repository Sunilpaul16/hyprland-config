pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Wallpaper list singleton
Singleton {
    id: root

    readonly property string wallpaperDir: Directories.wallpaperDir
    readonly property string thumbCacheDir: Directories.wallpaperThumbCache
    readonly property var videoExtensions: ["mp4", "webm", "mkv", "avi", "mov"]

    property var list: []
    property var thumbnailQueue: []
    property bool thumbnailBusy: false

    readonly property bool loading: scanProc.running

    signal thumbnailReady(string path)

    function isVideoName(name: string): bool {
        const ext = name.slice(name.lastIndexOf(".") + 1).toLowerCase();
        return videoExtensions.includes(ext);
    }

    // Fuzzy query
    function query(search: string): var {
        const trimmed = search.trim();
        if (!trimmed)
            return root.list;
        return Fuzzy.go(trimmed, root.list, { key: "name", all: true }).map(r => r.obj);
    }

    function thumbPathFor(path: string): string {
        return `${root.thumbCacheDir}/${Qt.md5(path)}.png`;
    }

    // Current wallpaper
    property string current: ""
    readonly property string currentPreview: root.current === "" ? "" : (root.isVideoName(root.current) ? root.thumbPathFor(root.current) : root.current)

    // Wallpaper file watch
    FileView {
        path: Directories.currentWallpaperFile
        watchChanges: true
        onLoaded: root.current = text().trim()
        onFileChanged: reload()
    }

    function randomFromCurrentFolder(): var {
        return root.list.length > 0 ? root.list[Math.floor(Math.random() * root.list.length)] : null;
    }

    // Apply wallpaper
    function apply(path: string): void {
        if (path)
            Quickshell.execDetached([Directories.switchwallScript, path]);
    }

    function applyRandom(): void {
        const entry = root.randomFromCurrentFolder();
        if (entry)
            root.apply(entry.path);
    }

    // Random wallpaper shortcut
    GlobalShortcut {
        name: "randomWallpaper"
        description: "Set a random wallpaper from the current folder"
        onPressed: root.applyRandom()
    }

    function refresh(): void {
        if (!scanProc.running)
            scanProc.running = true;
    }

    Component.onCompleted: root.refresh()

    // Scan wallpaper directory
    Process {
        id: scanProc
        command: ["find", root.wallpaperDir, "-maxdepth", "1", "-type", "f", "(",
            "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg",
            "-o", "-iname", "*.webp", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm",
            "-o", "-iname", "*.mkv", "-o", "-iname", "*.avi", "-o", "-iname", "*.mov",
            ")", "-printf", "%f\n"]

        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n").map(n => n.trim()).filter(n => n.length > 0).sort();
                root.list = names.map(name => {
                    const path = `${root.wallpaperDir}/${name}`;
                    const isVideo = root.isVideoName(name);
                    return {
                        name,
                        // Display label
                        label: name.replace(/\.[^.]+$/, ""),
                        path,
                        isVideo,
                        thumbPath: isVideo ? root.thumbPathFor(path) : path
                    };
                });
                for (const w of root.list) {
                    if (w.isVideo)
                        root.ensureThumbnail(w.path, w.thumbPath);
                }
                thumbPruneProc.keepPaths = root.list.filter(w => w.isVideo).map(w => w.thumbPath).join("\n");
                thumbPruneProc.running = true;
            }
        }
    }

    function ensureThumbnail(path: string, thumbPath: string): void {
        if (root.thumbnailQueue.some(entry => entry.path === path))
            return;
        root.thumbnailQueue = [...root.thumbnailQueue, { path, thumbPath }];
        root.startNextThumbnail();
    }

    function startNextThumbnail(): void {
        if (root.thumbnailBusy || root.thumbnailQueue.length === 0)
            return;
        const entry = root.thumbnailQueue[0];
        root.thumbnailQueue = root.thumbnailQueue.slice(1);
        root.thumbnailBusy = true;
        const proc = thumbGenComponent.createObject(root, entry);
        proc.running = true;
    }

    // Video thumbnail generator
    Component {
        id: thumbGenComponent

        Process {
            property string path
            property string thumbPath

            command: ["sh", "-c", "mkdir -p \"$(dirname \"$THUMB\")\" && { test -f \"$THUMB\" && test \"$THUMB\" -nt \"$SRC\" || ffmpeg -y -ss 00:00:01 -i \"$SRC\" -frames:v 1 -vf scale=480:-1 \"$THUMB\"; }"]
            environment: ({ SRC: path, THUMB: thumbPath })

            onExited: exitCode => {
                if (exitCode === 0)
                    root.thumbnailReady(path);
                root.thumbnailBusy = false;
                Qt.callLater(root.startNextThumbnail);
                destroy();
            }
        }
    }

    Process {
        id: thumbPruneProc
        property string keepPaths: ""
        command: ["sh", "-c", "test -d \"$CACHE\" || exit 0; find \"$CACHE\" -maxdepth 1 -type f -name '*.png' | while IFS= read -r file; do printf '%s\\n' \"$KEEP\" | grep -Fqx -- \"$file\" || rm -f -- \"$file\"; done"]
        environment: ({ CACHE: root.thumbCacheDir, KEEP: keepPaths })
    }
}
