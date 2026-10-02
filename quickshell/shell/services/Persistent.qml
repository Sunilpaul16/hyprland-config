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
    property alias gameModeEnabled: adapter.gameModeEnabled
    property alias gameModeDndWasEnabled: adapter.gameModeDndWasEnabled
    property alias gameModeIdleInhibitWasEnabled: adapter.gameModeIdleInhibitWasEnabled
    // Quick toggle layout
    property alias quickToggleLayout: adapter.quickToggleLayout
    // Last announced count
    property alias lastNotifiedUpdateTotal: adapter.lastNotifiedUpdateTotal
    // Overlay widget geometry
    property alias overlayWidgets: adapter.overlayWidgets
    property alias overlayScreen: adapter.overlayScreen

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
            property bool gameModeEnabled: false
            property bool gameModeDndWasEnabled: false
            property bool gameModeIdleInhibitWasEnabled: false
            property list<var> quickToggleLayout: []
            property bool wifiQuickToggleAdded: false
            property int lastNotifiedUpdateTotal: 0
            property string lastHyprlandInstanceSignature: ""
            property var overlayWidgets: ({})
            property string overlayScreen: ""
        }
    }

    // Snapshot after load
    Timer {
        id: snapshotTimer
        interval: 100
        repeat: false
        onTriggered: {
            // Add Wi-Fi once to existing layouts; users can still hide it afterwards.
            if (!adapter.wifiQuickToggleAdded) {
                if (adapter.quickToggleLayout.length > 0 && !adapter.quickToggleLayout.some(entry => entry.type === "wifi"))
                    adapter.quickToggleLayout = [{ type: "wifi", size: "small" }].concat(adapter.quickToggleLayout);
                adapter.wifiQuickToggleAdded = true;
            }
            root.isNewHyprlandInstance = (adapter.lastHyprlandInstanceSignature !== root.currentInstanceSignature);
            // Game mode is session-scoped; do not resurrect it after a new login.
            if (root.isNewHyprlandInstance)
                adapter.gameModeEnabled = false;
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
