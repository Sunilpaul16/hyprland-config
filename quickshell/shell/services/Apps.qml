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

    // Search-prefix flag -> the desktop-entry field it scopes matching to; "t" filters to terminal apps instead
    readonly property var searchFields: ({
        i: "id",
        c: "categories",
        d: "comment",
        e: "execString",
        w: "startupClass",
        g: "genericName",
        k: "keywords"
    })

    // Splits "@e firefox" into { key, terminalOnly, text }; anything else searches names unscoped
    function parseSearch(search: string): var {
        const prefix = Config.launcher.searchPrefix;
        const plain = {
            key: "name",
            terminalOnly: false,
            text: search.trim()
        };

        // Tested against the raw string, not a trimmed one: "@t " must still register as a flag
        // once its trailing space is the only thing left. Needs "<prefix><flag> " exactly.
        if (!prefix || !search.startsWith(prefix) || search[prefix.length + 1] !== " ")
            return plain;

        const flag = search[prefix.length];
        const rest = search.slice(prefix.length + 2).trim();
        if (flag === "t")
            return {
                key: "name",
                terminalOnly: true,
                text: rest
            };
        if (root.searchFields[flag])
            return {
                key: root.searchFields[flag],
                terminalOnly: false,
                text: rest
            };
        return plain;
    }

    // categories/keywords arrive as QVector<QString>, not a string, so fuzzysort's string key can't read them directly.
    // Length-checked rather than Array.isArray'd, since how QML marshals the vector isn't guaranteed to be a JS array.
    function fieldText(entry, key): string {
        const v = entry[key];
        if (v === undefined || v === null)
            return "";
        if (typeof v === "string")
            return v;
        if (v.length !== undefined) {
            let out = "";
            for (let i = 0; i < v.length; i++)
                out += (i ? " " : "") + v[i];
            return out;
        }
        return String(v);
    }

    // Fuzzy query, optionally field-scoped, re-ranked by launch history
    function query(search: string): var {
        const parsed = root.parseSearch(search);
        const pool = parsed.terminalOnly ? root.entries.filter(e => e.runInTerminal) : root.entries;

        if (!parsed.text)
            return pool.slice().sort((a, b) => root.countFor(b) - root.countFor(a) || a.name.localeCompare(b.name));

        // Flattened to {entry, text} so every field searches the same way whatever its underlying type
        const rows = pool.map(e => ({
            entry: e,
            text: root.fieldText(e, parsed.key)
        }));

        // Substring mode carries no score, so those results rank on history alone
        return Fuzzy.go(parsed.text, rows, {
            key: "text",
            all: true
        }).slice().sort((a, b) => root.rankScore(b.score ?? 1, b.obj.entry) - root.rankScore(a.score ?? 1, a.obj.entry)).map(r => r.obj.entry);
    }

    // Launch (terminal apps via the configured terminal's -e)
    function launch(entry): void {
        root.recordLaunch(entry);
        if (entry.runInTerminal)
            Quickshell.execDetached([Config.apps.terminal, "-e", ...entry.command]);
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
