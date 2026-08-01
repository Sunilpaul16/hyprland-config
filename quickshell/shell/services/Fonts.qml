pragma Singleton
import QtQuick
import Quickshell


// Resolves the configured font families against what is actually installed, and owns the two pickers' option lists
// Qt substitutes a missing family silently, so everything goes through resolve(), which falls back to a family known to be present
Singleton {
    id: root

    // Enumerated once — Qt.fontFamilies() walks fontconfig, so it is not
    // something to call per text site
    readonly property var installed: Qt.fontFamilies()

    // Resolved families
    readonly property string interfaceFamily: root.resolve(Config.appearance.fontInterface, "Noto Sans")
    readonly property string glyphFamily: root.resolve(Config.appearance.fontGlyph, "JetBrainsMono Nerd Font")

    // Interface picker options — a hand-picked shortlist (nothing distinguishes a UI-suitable family from the ~700 installed), filtered to what's present
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

    // Glyph picker options — enumerated rather than curated, since "ends in
    // Nerd Font" is an unambiguous filter that grows as fonts are installed
    readonly property var glyphOptions: root.installed
        .filter(f => /Nerd Font$/.test(f))
        .map(f => ({ value: f, label: f }))

    function resolve(want: string, fallback: string): string {
        if (want && root.installed.indexOf(want) !== -1)
            return want;
        return fallback;
    }
}
