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
    readonly property var videoExtensions: ["mp4", "webm", "mkv"]

    property var list: []

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

    // Wallpaper switchwall last applied, and a still of it usable as an Image
    // source — videos have no Image renderer, so those fall back to the thumb
    property string current: ""
    readonly property string currentPreview: root.current === "" ? "" : (root.isVideoName(root.current) ? root.thumbPathFor(root.current) : root.current)

    FileView {
        path: Directories.currentWallpaperFile
        watchChanges: true
        onLoaded: root.current = text().trim()
        onFileChanged: reload()
    }

    function randomFromCurrentFolder(): var {
        return root.list.length > 0 ? root.list[Math.floor(Math.random() * root.list.length)] : null;
    }

    function applyRandom(): void {
        const entry = root.randomFromCurrentFolder();
        if (entry)
            Quickshell.execDetached([Directories.switchwallScript, entry.path]);
    }

    // Bound to a Hyprland keybind via hl.dsp.global("quickshell:randomWallpaper")
    // — see hypr/keybinds.lua. (hyprctl's own dispatch CLI on this native-Lua
    // config build only accepts hl.dsp.* dispatcher expressions, not the
    // classic "global <name>" string form.)
    GlobalShortcut {
        name: "randomWallpaper"
        description: "Set a random wallpaper from the current folder"
        onPressed: root.applyRandom()
    }

    Component.onCompleted: scanProc.running = true

    // Scan wallpaper directory
    Process {
        id: scanProc
        command: ["find", root.wallpaperDir, "-maxdepth", "1", "-type", "f", "(",
            "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg",
            "-o", "-iname", "*.webp", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm",
            "-o", "-iname", "*.mkv", ")", "-printf", "%f\n"]

        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n").map(n => n.trim()).filter(n => n.length > 0).sort();
                root.list = names.map(name => {
                    const path = `${root.wallpaperDir}/${name}`;
                    const isVideo = root.isVideoName(name);
                    return {
                        name,
                        // Display form; `name` stays the full filename so fuzzy
                        // search can still match on extension
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
            }
        }
    }

    function ensureThumbnail(path: string, thumbPath: string): void {
        const proc = thumbGenComponent.createObject(root, { path, thumbPath });
        proc.running = true;
    }

    // Video thumbnail generator
    Component {
        id: thumbGenComponent

        Process {
            property string path
            property string thumbPath

            command: ["sh", "-c", "mkdir -p \"$(dirname \"$THUMB\")\" && { test -f \"$THUMB\" || ffmpeg -y -ss 00:00:01 -i \"$SRC\" -frames:v 1 -vf scale=480:-1 \"$THUMB\"; }"]
            environment: ({ SRC: path, THUMB: thumbPath })

            onExited: exitCode => {
                if (exitCode === 0)
                    root.thumbnailReady(path);
                destroy();
            }
        }
    }
}
