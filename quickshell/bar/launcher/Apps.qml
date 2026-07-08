pragma Singleton
import QtQuick
import Quickshell
import "fuzzysort.js" as Fuzzy

// Wraps Quickshell's built-in DesktopEntries service (no Caelestia plugin
// needed — this is a real Quickshell.DesktopEntries singleton, confirmed via
// its qmltypes). `entries` is a genuine reactive property binding rather than
// a one-off snapshot: DesktopEntries scans .desktop files asynchronously
// over the first second or so after the shell starts, and only a real
// binding (not an imperative read) reliably tracks that as entries arrive —
// verified empirically with a throwaway qs -p script before writing this.
Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    function query(search: string): var {
        const trimmed = search.trim();
        if (!trimmed)
            return root.entries;
        return Fuzzy.go(trimmed, root.entries, { key: "name", all: true }).map(r => r.obj);
    }

    // entry.command is already a parsed argv list with %f/%u/%U/%c field
    // codes stripped (confirmed empirically — e.g. Obsidian's execString
    // "/usr/bin/obsidian %U" comes through as command: ["/usr/bin/obsidian"])
    // so there's no field-code parsing to do here ourselves.
    function launch(entry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e", ...entry.command]);
        else
            Quickshell.execDetached(entry.command);
    }
}
