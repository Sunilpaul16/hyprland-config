pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reads matugen's colors.json and mutates Colors's properties in place, so
// a wallpaper change cross-fades the theme (via the Behaviors in
// Colors.qml) instead of restarting the shell. Singletons are lazy, so
// reapplyTheme() must be called once from shell.qml's Component.onCompleted
// or this never loads.
Singleton {
    id: root

    function reapplyTheme() {
        colorsFile.reload();
        applyTimer.restart();
    }

    function applyColors(text) {
        if (!text)
            return;

        let json;
        try {
            json = JSON.parse(text);
        } catch (e) {
            return;
        }

        for (const key in json) {
            if (Colors.hasOwnProperty(key))
                Colors[key] = json[key];
        }
    }

    // onLoadedChanged only fires on the loaded<->not-loaded transition, not
    // on every reload() while already loaded — so re-reads after the first
    // one go through this debounced timer instead, applying reload()'d
    // text() directly rather than depending on that signal firing again
    Timer {
        id: applyTimer
        interval: 50
        repeat: false
        onTriggered: root.applyColors(colorsFile.text())
    }

    FileView {
        id: colorsFile
        path: Directories.colorsFile
        watchChanges: true

        onFileChanged: root.reapplyTheme()
        onLoadedChanged: root.applyColors(text())
    }
}
