pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Pending package updates
Singleton {
    id: root

    // [{ name, from, to }]
    property list<var> repoUpdates: []
    property list<var> aurUpdates: []

    readonly property int repoCount: root.repoUpdates.length
    readonly property int aurCount: root.aurUpdates.length
    readonly property int total: root.repoCount + root.aurCount

    // Poked by shell.qml
    property bool backgroundChecking: false

    property bool checking: false
    // Epoch ms
    property real lastChecked: 0

    readonly property string aurHelper: Config.updates.aurHelper

    readonly property string lastCheckedLabel: {
        // Tick dependency
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

    // Label tick
    property int _labelTick: 0

    // Upgrade in terminal
    function runUpgrade(): void {
        Quickshell.execDetached([Config.apps.terminal, "-e", root.aurHelper, "-Syu"]);
    }

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

    // Last announced count
    property int _lastNotifiedTotal: Persistent.isNewHyprlandInstance ? 0 : Persistent.lastNotifiedUpdateTotal

    function _settle(): void {
        if (!root._repoDone || !root._aurDone)
            return;
        root.checking = false;
        root.lastChecked = Date.now();
        root._notifyIfGrown();
    }

    // Notify on growth
    function _notifyIfGrown(): void {
        if (Config.updates.notify && root.total > root._lastNotifiedTotal)
            Quickshell.execDetached(["notify-send", "-a", "quickshell", "-i", "system-software-update", `${root.total} update${root.total === 1 ? "" : "s"} available`, `${root.repoCount} from the repos, ${root.aurCount} from the AUR.`]);
        // Owns value now
        root._lastNotifiedTotal = root.total;
        Persistent.lastNotifiedUpdateTotal = root.total;
    }

    // Parse update lines
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

        // Exit 2 = none
        onExited: exitCode => {
            if (exitCode === 2)
                root.repoUpdates = [];
            root._repoDone = true;
            root._settle();
        }

        // Covers failure to start
        onRunningChanged: {
            if (!repoProc.running && root.checking && !root._repoDone) {
                root.repoUpdates = [];
                root._repoDone = true;
                root._settle();
            }
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

        // Covers failure to start
        onRunningChanged: {
            if (!aurProc.running && root.checking && !root._aurDone) {
                root.aurUpdates = [];
                root._aurDone = true;
                root._settle();
            }
        }
    }

    // Deferred first check
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

    // Label refresh
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root._labelTick++
    }
}
