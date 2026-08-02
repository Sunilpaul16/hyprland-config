pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Installed apps singleton
Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    // Desktop-entry id -> launch count, persisted outside the hot-reloaded tree
    property var launchCounts: ({})

    function countFor(entry): int {
        return (entry && root.launchCounts[entry.id]) || 0;
    }

    // Multiplicative, so history lifts a match but can never promote a miss — fuzzysort normalises a non-match to exactly 0
    function rankScore(score: real, entry): real {
        return score * (1 + Config.launcher.frequencyWeight * Math.log(1 + root.countFor(entry)));
    }

    // Fuzzy query, re-ranked by launch history
    function query(search: string): var {
        const trimmed = search.trim();
        if (!trimmed)
            return root.entries.slice().sort((a, b) => root.countFor(b) - root.countFor(a) || a.name.localeCompare(b.name));

        // Substring mode carries no score, so those results rank on history alone
        return Fuzzy.go(trimmed, root.entries, {
            key: "name",
            all: true
        }).slice().sort((a, b) => root.rankScore(b.score ?? 1, b.obj) - root.rankScore(a.score ?? 1, a.obj)).map(r => r.obj);
    }

    // Launch (terminal apps via kitty -e)
    function launch(entry): void {
        root.recordLaunch(entry);
        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e", ...entry.command]);
        else
            Quickshell.execDetached(entry.command);
    }

    // Reassigned rather than mutated in place, so bindings reading launchCounts re-evaluate
    function recordLaunch(entry): void {
        if (!entry || !entry.id)
            return;
        const next = Object.assign({}, root.launchCounts);
        next[entry.id] = (next[entry.id] || 0) + 1;
        root.launchCounts = next;
        saveTimer.restart();
    }

    // Launch-count store
    FileView {
        id: usageFile
        path: Directories.appUsageFile

        onLoaded: {
            try {
                root.launchCounts = JSON.parse(usageFile.text() || "{}");
            } catch (e) {
                root.launchCounts = ({});
            }
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                usageFile.setText("{}");
        }
    }

    // Debounced write
    Timer {
        id: saveTimer
        interval: 400
        repeat: false
        onTriggered: usageFile.setText(JSON.stringify(root.launchCounts))
    }
}
