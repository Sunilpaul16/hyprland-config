pragma Singleton
import QtQuick
import Quickshell


// Icon resolution singleton
Singleton {
    id: root
    readonly property var desktopEntries: DesktopEntries.applications.values

    // Category to glyph
    readonly property var categoryIcons: ({
            WebBrowser: "web",
            Printing: "print",
            Security: "security",
            Network: "chat",
            Archiving: "archive",
            Compression: "archive",
            Development: "code",
            IDE: "code",
            TextEditor: "edit_note",
            Audio: "music_note",
            Music: "music_note",
            Player: "music_note",
            Recorder: "mic",
            Game: "sports_esports",
            FileTools: "files",
            FileManager: "files",
            Filesystem: "files",
            FileTransfer: "files",
            Settings: "settings",
            DesktopSettings: "settings",
            HardwareSettings: "settings",
            TerminalEmulator: "terminal",
            ConsoleOnly: "terminal",
            Utility: "build",
            Monitor: "monitor_heart",
            Midi: "graphic_eq",
            Mixer: "graphic_eq",
            AudioVideoEditing: "video_settings",
            AudioVideo: "music_video",
            Video: "videocam",
            Building: "construction",
            Graphics: "photo_library",
            "2DGraphics": "photo_library",
            RasterGraphics: "photo_library",
            TV: "tv",
            System: "host",
            Office: "content_paste"
        })

    // Resolve icon name
    function resolve(wmClass) {
        if (!wmClass)
            return "";
        const lower = wmClass.toLowerCase();
        const entry = root.desktopEntries.find(e => (e.startupClass && e.startupClass.toLowerCase() === lower) || e.id.toLowerCase() === lower || e.id.toLowerCase() === `${lower}.desktop`);
        return entry ? entry.icon : "";
    }

    // Resolve category glyph
    function categoryFor(wmClass, fallback) {
        if (!wmClass)
            return fallback;
        const categories = DesktopEntries.heuristicLookup(wmClass)?.categories;
        if (categories)
            for (const [key, value] of Object.entries(root.categoryIcons))
                if (categories.includes(key))
                    return value;
        return fallback;
    }
}
