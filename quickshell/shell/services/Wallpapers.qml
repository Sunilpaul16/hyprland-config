pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "fuzzysort.js" as Fuzzy

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
