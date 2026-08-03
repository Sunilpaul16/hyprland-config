pragma Singleton
import QtQuick
import Quickshell


// Font resolution
Singleton {
    id: root

    // Installed families
    readonly property var installed: Qt.fontFamilies()

    // Resolved families
    readonly property string interfaceFamily: root.resolve(Config.appearance.fontInterface, "Noto Sans")
    readonly property string glyphFamily: root.resolve(Config.appearance.fontGlyph, "JetBrainsMono Nerd Font")

    // Interface options
    readonly property var interfaceOptions: [
        "Noto Sans",
        "Rubik",
        "Adwaita Sans",
        "Open Sans",
        "Space Grotesk",
        "Readex Pro",
        "Carlito",
        "DejaVu Sans",
        "Liberation Sans",
        "VT323"
    ].filter(f => root.installed.indexOf(f) !== -1).map(f => ({ value: f, label: f }))

    // Glyph options
    readonly property var glyphOptions: root.installed
        .filter(f => /Nerd Font$/.test(f))
        .map(f => ({ value: f, label: f }))

    function resolve(want: string, fallback: string): string {
        if (want && root.installed.indexOf(want) !== -1)
            return want;
        return fallback;
    }
}
