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

    // Dashboard card sizing (defaults ported from caelestia's Tokens.sizes.dashboard)
    property alias dashboardUserWidth: adapter.dashboardUserWidth
    property alias dashboardWeatherWidth: adapter.dashboardWeatherWidth
    property alias dashboardMediaCardWidth: adapter.dashboardMediaCardWidth
    property alias dashboardMediaCoverArtSize: adapter.dashboardMediaCoverArtSize
    property alias dashboardResourceRingThickness: adapter.dashboardResourceRingThickness
    property alias dashboardMediaProgressThickness: adapter.dashboardMediaProgressThickness
    property alias dashboardMediaProgressSweep: adapter.dashboardMediaProgressSweep

    // User card avatar — set to an absolute image path to override the
    // ~/.face default (no in-app picker; edit config.json directly)
    property alias userAvatarPath: adapter.userAvatarPath

    // Gates panels from reading config before the FileView has loaded
    property bool ready: false

    // Config file
    FileView {
        id: configFile
        path: Directories.configFile
        watchChanges: true

        onLoaded: root.ready = true
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
            property int dashboardUserWidth: 340
            property int dashboardWeatherWidth: 275
            property int dashboardMediaCardWidth: 200
            property int dashboardMediaCoverArtSize: 200
            property int dashboardResourceRingThickness: 6
            property int dashboardMediaProgressThickness: 6
            property int dashboardMediaProgressSweep: 180
            property string userAvatarPath: ""
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
