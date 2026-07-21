pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Runtime UI state that should survive a shell-only restart (SUPER+CTRL+R)
// but NOT a fresh Hyprland login — separate from Config.qml, which holds
// user preferences, not transient toggle state.
Singleton {
    id: root

    readonly property string currentInstanceSignature: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""

    // Set once when the state file finishes loading (or fails to load,
    // meaning there's no prior state at all). Conservative default of true
    // (treat as a fresh instance / don't restore) covers the brief window
    // before the FileView resolves.
    property bool isNewHyprlandInstance: true

    property alias nightLightEnabled: adapter.nightLightEnabled
    property alias idleInhibitEnabled: adapter.idleInhibitEnabled
    property alias screenRecorderCardEnabled: adapter.screenRecorderCardEnabled
    property alias keepAwakeCardEnabled: adapter.keepAwakeCardEnabled
    property alias dndEnabled: adapter.dndEnabled
    // Ordered [{type, size}] — a missing entry is new since the layout was last saved (comparison.md #36)
    property alias quickToggleLayout: adapter.quickToggleLayout

    // State file
    FileView {
        id: stateFile
        path: Directories.stateFile
        watchChanges: true

        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        // loaded flips true before JsonAdapter finishes parsing the loaded
        // text into its properties, so a same-tick read here would still
        // see lastHyprlandInstanceSignature's declared default rather than
        // the stored value — snapshotTimer's short delay is a real fix for
        // that ordering gap, not a race worked around by luck.
        onLoadedChanged: snapshotTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                snapshotTimer.restart();
                writeAdapter();
            }
        }

        // Persisted values
        JsonAdapter {
            id: adapter
            property bool nightLightEnabled: false
            property bool idleInhibitEnabled: false
            property bool screenRecorderCardEnabled: false
            property bool keepAwakeCardEnabled: false
            property bool dndEnabled: false
            property list<var> quickToggleLayout: []
            property string lastHyprlandInstanceSignature: ""
        }
    }

    // One-time snapshot of isNewHyprlandInstance, taken once the loaded
    // JsonAdapter has settled (see onLoadedChanged above)
    Timer {
        id: snapshotTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.isNewHyprlandInstance = (adapter.lastHyprlandInstanceSignature !== root.currentInstanceSignature);
            adapter.lastHyprlandInstanceSignature = root.currentInstanceSignature;
        }
    }

    // Debounced write
    Timer {
        id: writeTimer
        interval: 50
        repeat: false
        onTriggered: stateFile.writeAdapter()
    }

    // Debounced reload
    Timer {
        id: reloadTimer
        interval: 50
        repeat: false
        onTriggered: stateFile.reload()
    }
}
