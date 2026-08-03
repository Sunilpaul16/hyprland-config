pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Installed apps singleton
Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    // Launch counts
    property var launchCounts: ({})

    function countFor(entry): int {
        return (entry && root.launchCounts[entry.id]) || 0;
    }

    // History multiplier
    function rankScore(score: real, entry): real {
        return score * (1 + Config.launcher.frequencyWeight * Math.log(1 + root.countFor(entry)));
    }

    // Search prefix fields
    readonly property var searchFields: ({
        i: "id",
        c: "categories",
        d: "comment",
        e: "execString",
        w: "startupClass",
        g: "genericName",
        k: "keywords"
    })

    // Parse search flags
    function parseSearch(search: string): var {
        const prefix = Config.launcher.searchPrefix;
        const plain = {
            key: "name",
            terminalOnly: false,
            text: search.trim()
        };

        // Flag needs space
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

    // Vector field text
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

    // Fuzzy query
    function query(search: string): var {
        const parsed = root.parseSearch(search);
        const pool = parsed.terminalOnly ? root.entries.filter(e => e.runInTerminal) : root.entries;

        if (!parsed.text)
            return pool.slice().sort((a, b) => root.countFor(b) - root.countFor(a) || a.name.localeCompare(b.name));

        // Flatten to rows
        const rows = pool.map(e => ({
            entry: e,
            text: root.fieldText(e, parsed.key)
        }));

        // Substring mode
        return Fuzzy.go(parsed.text, rows, {
            key: "text",
            all: true
        }).slice().sort((a, b) => root.rankScore(b.score ?? 1, b.obj.entry) - root.rankScore(a.score ?? 1, a.obj.entry)).map(r => r.obj.entry);
    }

    // Launch via uwsm
    function launch(entry): void {
        root.recordLaunch(entry);
        if (entry.runInTerminal)
            Quickshell.execDetached(["uwsm", "app", "--", Config.apps.terminal, "-e", ...entry.command]);
        else
            Quickshell.execDetached(["uwsm", "app", "--", ...entry.command]);
    }

    // Reassign for bindings
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
