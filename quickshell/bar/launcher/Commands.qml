pragma Singleton
import QtQuick
import Quickshell
import "fuzzysort.js" as Fuzzy

// The list shown when the search text starts with ">" (see Content.qml's
// `mode` property). Each entry is a mode you can switch the launcher into —
// selecting one rewrites the search text to `>{mode} `, which Content.qml's
// mode computation then picks up reactively. Add more commands here as more
// modes are built (e.g. a future "power" or "calc" entry); nothing else in
// Content.qml needs to change to support a new one, as long as there's a
// results area registered for that mode.
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
