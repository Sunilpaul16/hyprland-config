pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Runtime UI state
Singleton {
    id: root

    readonly property string currentInstanceSignature: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""

    // Fresh login flag
    property bool isNewHyprlandInstance: true

    property alias nightLightEnabled: adapter.nightLightEnabled
    property alias idleInhibitEnabled: adapter.idleInhibitEnabled
    property alias screenRecorderCardEnabled: adapter.screenRecorderCardEnabled
    property alias keepAwakeCardEnabled: adapter.keepAwakeCardEnabled
    property alias dndEnabled: adapter.dndEnabled
    // Quick toggle layout
    property alias quickToggleLayout: adapter.quickToggleLayout
    // Last announced count
    property alias lastNotifiedUpdateTotal: adapter.lastNotifiedUpdateTotal

    // State file
    FileView {
        id: stateFile
        path: Directories.stateFile
        watchChanges: true

        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        // Settle before read
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
            property int lastNotifiedUpdateTotal: 0
            property string lastHyprlandInstanceSignature: ""
        }
    }

    // Snapshot after load
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
