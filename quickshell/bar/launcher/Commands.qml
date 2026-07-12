pragma Singleton
import QtQuick
import Quickshell
import "fuzzysort.js" as Fuzzy


Singleton {
    id: root

    readonly property var list: [
        { name: "wallpaper", title: "Wallpaper", description: "Change the current wallpaper", icon: "\u{1F5BC}\u{FE0F}" },
        { name: "clip", title: "Clipboard", description: "Browse clipboard history", icon: "\u{1F4CB}" }
    ]

    function query(search: string): var {
        const trimmed = search.trim();
        if (!trimmed)
            return root.list;
        return Fuzzy.go(trimmed, root.list, { key: "name", all: true }).map(r => r.obj);
    }
}
