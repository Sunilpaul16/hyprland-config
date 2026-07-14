pragma Singleton
import QtQuick
import Quickshell
import "fuzzysort.js" as Fuzzy

// Installed apps singleton
Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    // Fuzzy query
    function query(search: string): var {
        const trimmed = search.trim();
        if (!trimmed)
            return root.entries;
        return Fuzzy.go(trimmed, root.entries, { key: "name", all: true }).map(r => r.obj);
    }

    // Launch (terminal apps via kitty -e)
    function launch(entry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e", ...entry.command]);
        else
            Quickshell.execDetached(entry.command);
    }
}
