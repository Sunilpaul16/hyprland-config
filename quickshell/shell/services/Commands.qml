pragma Singleton
import QtQuick
import Quickshell


// Launcher commands singleton
Singleton {
    id: root

    readonly property var list: [
        { name: "wallpaper", label: "Wallpaper", description: "Change the current wallpaper", icon: "\u{1F5BC}\u{FE0F}" },
        { name: "clip", label: "Clipboard", description: "Browse clipboard history", icon: "\u{1F4CB}" },
        { name: "scheme", label: "Scheme", description: "Switch to a static colour palette", icon: "\u{1F3A8}" },
        { name: "variant", label: "Variant", description: "Change how colours derive from the wallpaper", icon: "\u{1F308}" },
        { name: "light", label: "Light mode", description: "Switch the theme to light", icon: "\u{2600}\u{FE0F}", execute: () => Theme.setMode("light") },
        { name: "dark", label: "Dark mode", description: "Switch the theme to dark", icon: "\u{1F319}", execute: () => Theme.setMode("dark") },
        { name: "auto", label: "Automatic mode", description: "Let the wallpaper decide light or dark", icon: "\u{1F313}", execute: () => Theme.setMode("auto") }
    ]

    // Fuzzy query
    function query(search: string): var {
        const trimmed = search.trim();
        if (!trimmed)
            return root.list;
        return Fuzzy.go(trimmed, root.list, { key: "name", all: true }).map(r => r.obj);
    }
}
