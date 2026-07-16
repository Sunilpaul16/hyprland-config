pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// JSON-backed runtime config. Mirrors end-4/dots-hyprland's Config.qml
// pattern: FileView + JsonAdapter, a debounced write on adapterUpdated (any
// property change anywhere in the adapter), a debounced reload when the
// file changes externally (watchChanges), and a FileNotFound-only
// load-failure fallback that writes the in-memory defaults to create the
// file on first run. File lives at ~/.config/quickshell/config.json --
// deliberately NOT under quickshell/shell/, which is the directory this
// shell hot-reloads on any change (see switchwall's --preview comment);
// writing a live-edited JSON file in there would reset the whole shell on
// every single setting change.
Singleton {
    id: root

    property alias use12Hour: adapter.use12Hour
    property alias barHeight: adapter.barHeight
    property alias toastDismissDuration: adapter.toastDismissDuration

    FileView {
        id: configFile
        path: Quickshell.env("HOME") + "/.config/quickshell/config.json"
        watchChanges: true

        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property bool use12Hour: false
            property int barHeight: 40
            property int toastDismissDuration: 5000
        }
    }

    // Debounce writes: adapterUpdated fires on every nested property
    // change, so batch bursts (e.g. several settings flipped at once) into
    // one disk write instead of one per property.
    Timer {
        id: writeTimer
        interval: 50
        repeat: false
        onTriggered: configFile.writeAdapter()
    }

    // Debounce reloads: watchChanges only emits fileChanged(), it doesn't
    // reload automatically -- this is what makes an external hand-edit to
    // the JSON file actually take effect live.
    Timer {
        id: reloadTimer
        interval: 50
        repeat: false
        onTriggered: configFile.reload()
    }
}
