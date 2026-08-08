pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Theme mode and source
Singleton {
    id: root

    // "auto" | "light" | "dark"
    property string mode: "auto"
    // Pipeline is slow
    property bool busy: false
    property bool lastRunFailed: false
    property bool _exited: false

    // "dynamic" | "<scheme>/<flavour>"
    property string source: "dynamic"
    readonly property bool usingPreset: root.source !== "dynamic"

    readonly property string modeLabel: {
        if (root.mode === "light")
            return "Light";
        if (root.mode === "dark")
            return "Dark";
        return "Automatic";
    }

    // Set mode
    function setMode(value: string): void {
        if (root.busy || value === root.mode)
            return;
        root.busy = true;
        root.lastRunFailed = false;
        root._exited = false;
        modeProc.command = [Directories.switchwallScript, "--mode", value];
        modeProc.running = true;
    }

    // Regenerate theme
    function regenerate(): void {
        if (root.busy)
            return;
        root.busy = true;
        root.lastRunFailed = false;
        root._exited = false;
        modeProc.command = [Directories.switchwallScript, "--noswitch"];
        modeProc.running = true;
    }

    // Discard cached frames and analysis
    function refresh(): void {
        if (root.busy)
            return;
        root.busy = true;
        root.lastRunFailed = false;
        root._exited = false;
        modeProc.command = [Directories.switchwallScript, "--refresh"];
        modeProc.running = true;
    }

    function applyPreset(id: string): void {
        if (root.busy)
            return;
        root.busy = true;
        root.lastRunFailed = false;
        root._exited = false;
        modeProc.command = [Directories.setschemeScript, id];
        modeProc.running = true;
    }

    // Any preset, or dynamic
    function applyRandomPreset(): void {
        if (root.busy)
            return;
        root.busy = true;
        root.lastRunFailed = false;
        root._exited = false;
        modeProc.command = [Directories.setschemeScript, "--random"];
        modeProc.running = true;
    }

    function setDynamic(): void {
        if (root.busy || !root.usingPreset)
            return;
        root.busy = true;
        root.lastRunFailed = false;
        root._exited = false;
        modeProc.command = [Directories.setschemeScript, "dynamic"];
        modeProc.running = true;
    }

    Process {
        id: modeProc

        onExited: exitCode => {
            root._exited = true;
            root.lastRunFailed = exitCode !== 0;
        }

        // Also fires on failure to start
        onRunningChanged: {
            if (!modeProc.running) {
                if (!root._exited)
                    root.lastRunFailed = true;
                root.busy = false;
            }
        }
    }

    // Colour source file
    FileView {
        path: Directories.colorSourceFile
        watchChanges: true

        onLoaded: {
            const value = text().trim();
            if (value.length > 0)
                root.source = value;
        }
        onFileChanged: reload()
    }

    // Colour mode file
    FileView {
        path: Directories.colorModeFile
        watchChanges: true

        onLoaded: {
            const value = text().trim();
            if (value.length > 0)
                root.mode = value;
        }
        onFileChanged: reload()
    }
}
