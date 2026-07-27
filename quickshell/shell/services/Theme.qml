pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Light/dark mode and theme regeneration, both driven through switchwall so
// the shell never regenerates colours by a second, divergent path
Singleton {
    id: root

    // "auto" | "light" | "dark" — auto picks by wallpaper brightness
    property string mode: "auto"
    // switchwall runs matugen plus a whole materialyoucolor pass, so this is
    // seconds rather than instant
    property bool busy: false

    readonly property string modeLabel: {
        if (root.mode === "light")
            return "Light";
        if (root.mode === "dark")
            return "Dark";
        return "Automatic";
    }

    // `--mode` persists the choice itself and re-themes the current wallpaper
    function setMode(value: string): void {
        if (root.busy || value === root.mode)
            return;
        root.busy = true;
        modeProc.command = [Directories.switchwallScript, "--mode", value];
        modeProc.running = true;
    }

    // Re-runs the pipeline against the wallpaper already set
    function regenerate(): void {
        if (root.busy)
            return;
        root.busy = true;
        modeProc.command = [Directories.switchwallScript, "--noswitch"];
        modeProc.running = true;
    }

    Process {
        id: modeProc
        onExited: root.busy = false
    }

    // switchwall owns this file, so read it rather than tracking the mode
    // separately — an external `switchwall --mode dark` stays in sync
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
