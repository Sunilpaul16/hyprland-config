pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "fuzzysort.js" as Fuzzy

// Scans the wallpaper folder once at startup and answers fuzzy-filtered
// queries for Content.qml's search field. Thumbnails for video wallpapers
// are generated lazily (once per file, cached by content hash of the path)
// since there's no cheap way to preview a video frame without decoding it.
Singleton {
    id: root

    readonly property string wallpaperDir: "/home/spaul16/wallpaper"
    readonly property string thumbCacheDir: Quickshell.env("HOME") + "/.cache/wallpaper-thumbs"
    readonly property var videoExtensions: ["mp4", "webm", "mkv"]

    // [{ name, path, isVideo, thumbPath }, ...] — thumbPath is the file to
    // hand to Image: the wallpaper itself for images, a generated frame for
    // videos (may not exist on disk yet — see thumbnailReady below).
    property var list: []

    signal thumbnailReady(string path)

    function isVideoName(name: string): bool {
        const ext = name.slice(name.lastIndexOf(".") + 1).toLowerCase();
        return videoExtensions.includes(ext);
    }

    // Empty search returns everything in scan order; otherwise fuzzy-match
    // filenames. Kept as the one entry point Content.qml calls, so a future
    // app-search mode can live behind the same shape without Content needing
    // to know about Wallpapers directly.
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

    // One-shot Process per video, created on demand (createObject) rather
    // than a fixed pool since there's no bound on how many videos exist.
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
