pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Runtime config singleton (JSON-backed)
Singleton {
    id: root

    property alias use12Hour: adapter.use12Hour
    property alias barHeight: adapter.barHeight
    property alias toastDismissDuration: adapter.toastDismissDuration

    // Config file
    FileView {
        id: configFile
        path: Directories.configFile
        watchChanges: true

        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        // Persisted values
        JsonAdapter {
            id: adapter
            property bool use12Hour: false
            property int barHeight: 40
            property int toastDismissDuration: 5000
        }
    }

    // Debounced write
    Timer {
        id: writeTimer
        interval: 50
        repeat: false
        onTriggered: configFile.writeAdapter()
    }

    // Debounced reload
    Timer {
        id: reloadTimer
        interval: 50
        repeat: false
        onTriggered: configFile.reload()
    }
}
