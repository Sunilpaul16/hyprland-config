pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Pending package updates. `checkupdates` (pacman-contrib) for the official
// repos and an AUR helper for the rest — both are read-only queries against a
// temporary database, neither touches the installed system
Singleton {
    id: root

    // [{ name, from, to }]
    property list<var> repoUpdates: []
    property list<var> aurUpdates: []

    readonly property int repoCount: root.repoUpdates.length
    readonly property int aurCount: root.aurUpdates.length
    readonly property int total: root.repoCount + root.aurCount

    // Set by shell.qml. Doubles as the reason this singleton exists at all:
    // nothing else references Updates, and a lazy singleton's timers never
    // start, so "check on login" would silently mean "check when the settings
    // page is first opened" (same reason ColorsLoader is poked from shell.qml)
    property bool backgroundChecking: false

    property bool checking: false
    // Epoch ms; 0 until the first check completes
    property real lastChecked: 0

    readonly property string aurHelper: Config.updates.aurHelper

    readonly property string lastCheckedLabel: {
        // Date.now() is not a binding dependency, so the tick is what makes
        // this re-evaluate as time passes
        root._labelTick;
        if (root.checking)
            return "Checking…";
        if (root.lastChecked === 0)
            return "Not checked yet";
        const mins = Math.floor((Date.now() - root.lastChecked) / 60000);
        if (mins < 1)
            return "Just now";
        if (mins < 60)
            return `${mins} minute${mins === 1 ? "" : "s"} ago`;
        const hours = Math.floor(mins / 60);
        return `${hours} hour${hours === 1 ? "" : "s"} ago`;
    }

    // Ticks the relative label along without re-running the check
    property int _labelTick: 0

    function refresh(): void {
        if (root.checking)
            return;
        root.checking = true;
        root._repoDone = false;
        root._aurDone = false;
        repoProc.running = true;
        aurProc.running = true;
    }

    property bool _repoDone: false
    property bool _aurDone: false

    // Last count announced, so a re-check finding the same updates stays quiet.
    // Restored from Persistent so a shell-only restart stays quiet too; a fresh
    // Hyprland login starts at 0 and announces once
    property int _lastNotifiedTotal: Persistent.isNewHyprlandInstance ? 0 : Persistent.lastNotifiedUpdateTotal

    function _settle(): void {
        if (!root._repoDone || !root._aurDone)
            return;
        root.checking = false;
        root.lastChecked = Date.now();
        root._notifyIfGrown();
    }

    // Fires only when the pending count grows. Assigning unconditionally means
    // an upgrade that drops the count re-arms it for the next batch
    function _notifyIfGrown(): void {
        if (Config.updates.notify && root.total > root._lastNotifiedTotal)
            Quickshell.execDetached(["notify-send", "-a", "quickshell", "-i", "system-software-update", `${root.total} update${root.total === 1 ? "" : "s"} available`, `${root.repoCount} from the repos, ${root.aurCount} from the AUR.`]);
        // Assigning breaks the binding above, so this owns the value from here on
        root._lastNotifiedTotal = root.total;
        Persistent.lastNotifiedUpdateTotal = root.total;
    }

    // "hyprland 0.56.0-2 -> 0.56.1-1"
    function parseLines(text: string): var {
        return text.trim().split("\n").filter(l => l.trim().length > 0).map(line => {
            const parts = line.trim().split(/\s+/);
            return {
                name: parts[0] ?? line,
                from: parts[1] ?? "",
                to: parts[3] ?? ""
            };
        });
    }

    Process {
        id: repoProc
        command: ["checkupdates"]

        stdout: StdioCollector {
            onStreamFinished: root.repoUpdates = root.parseLines(text)
        }

        // checkupdates exits 2 when there is simply nothing to update
        onExited: exitCode => {
            if (exitCode === 2)
                root.repoUpdates = [];
            root._repoDone = true;
            root._settle();
        }
    }

    Process {
        id: aurProc
        command: [root.aurHelper, "-Qua"]

        stdout: StdioCollector {
            onStreamFinished: root.aurUpdates = root.parseLines(text)
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                root.aurUpdates = [];
            root._aurDone = true;
            root._settle();
        }
    }

    // Deferred rather than immediate: the shell hot-reloads on every file
    // save, and an immediate check would re-query the AUR on each one
    Timer {
        interval: 10000
        running: root.backgroundChecking && Config.ready && Config.updates.autoCheck
        repeat: false
        onTriggered: root.refresh()
    }

    // Background check schedule
    Timer {
        interval: Math.max(15, Config.updates.intervalMinutes) * 60000
        running: root.backgroundChecking && Config.ready && Config.updates.autoCheck
        repeat: true
        onTriggered: root.refresh()
    }

    // Keeps relative "x ago" labels fresh
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root._labelTick++
    }
}
