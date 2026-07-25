pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Runtime config singleton (JSON-backed)
Singleton {
    id: root

    property alias use12Hour: adapter.use12Hour                                       // true = 12-hour clock (AM/PM); false = 24-hour
    property alias barHeight: adapter.barHeight                                       // top bar height (px)
    property alias toastDismissDuration: adapter.toastDismissDuration                 // ms a notification toast shows before auto-dismissing

    // Dashboard card sizing (defaults ported from caelestia's Tokens.sizes.dashboard)
    property alias dashboardUserWidth: adapter.dashboardUserWidth                         // Dashboard tab: User card width (px)
    property alias dashboardWeatherWidth: adapter.dashboardWeatherWidth                   // Dashboard tab: small Weather card width (px)
    property alias dashboardMediaCardWidth: adapter.dashboardMediaCardWidth               // Dashboard tab: condensed Media card width (px)
    property alias dashboardMediaCoverArtSize: adapter.dashboardMediaCoverArtSize         // Media tab: cover art side length (px)
    property alias dashboardResourceRingThickness: adapter.dashboardResourceRingThickness // Dashboard tab: CPU/Memory/Disk ring stroke width (px)
    property alias dashboardResourceRingSize: adapter.dashboardResourceRingSize           // Dashboard tab: max CPU/Memory/Disk ring diameter (px)
    property alias dashboardMediaProgressThickness: adapter.dashboardMediaProgressThickness // Media card: playback progress arc stroke width (px)
    property alias dashboardMediaProgressSweep: adapter.dashboardMediaProgressSweep       // Media card: progress arc span in degrees (180 = half-circle)
    property alias dashboardDateTimeWidth: adapter.dashboardDateTimeWidth                 // Dashboard tab: clock card width (px)
    property alias dashboardClockFontSize: adapter.dashboardClockFontSize                 // Clock card: hour/minute glyph size (px)
    property alias dashboardLogoSize: adapter.dashboardLogoSize                           // User card: distro logo badge glyph size (px)
    property alias dashboardAvatarSize: adapter.dashboardAvatarSize                       // User card: avatar diameter (px)
    property alias dashboardUptimeSize: adapter.dashboardUptimeSize                       // User card: uptime badge diameter (px)
    property alias dashboardWeatherIconSize: adapter.dashboardWeatherIconSize             // Weather card: condition glyph size (px)
    property alias dashboardWeatherTempSize: adapter.dashboardWeatherTempSize             // Weather card: temperature text size (px)

    // Media card animated gif (caelestia's bongocat). Empty path = the
    // repo's bundled assets/bongocat.gif
    property alias dashboardMediaGifEnabled: adapter.dashboardMediaGifEnabled
    property alias dashboardMediaGifPath: adapter.dashboardMediaGifPath
    property alias dashboardMediaGifSpeed: adapter.dashboardMediaGifSpeed                 // Media card: gif playback rate multiplier (1.0 = native)

    // Dashboard panel size — "auto" measures/fills as today; "fixed" uses the
    // paired pixel value below, clamped to 95% of screen size as a safety ceiling
    property alias dashboardPanelWidthMode: adapter.dashboardPanelWidthMode   // "auto" | "fixed"
    property alias dashboardPanelWidth: adapter.dashboardPanelWidth           // px width used only when widthMode is "fixed"
    property alias dashboardPanelHeightMode: adapter.dashboardPanelHeightMode // "auto" | "fixed"
    property alias dashboardPanelHeight: adapter.dashboardPanelHeight         // px height used only when heightMode is "fixed"

    // User card avatar — absolute, ~-rooted or repo-relative image path; "" falls back to ~/.face then the bundled bongocat
    property alias userAvatarPath: adapter.userAvatarPath

    // Sidebar notifications empty-state watermark; "" = the bundled assets/dino.png
    property alias sidebarNoNotifsImage: adapter.sidebarNoNotifsImage

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
            property int dashboardResourceRingSize: 64
            property int dashboardMediaProgressThickness: 6
            property int dashboardMediaProgressSweep: 180
            property int dashboardDateTimeWidth: 110
            property int dashboardClockFontSize: 42
            property int dashboardLogoSize: 30
            property int dashboardAvatarSize: 96
            property int dashboardUptimeSize: 30
            property int dashboardWeatherIconSize: 64
            property int dashboardWeatherTempSize: 38
            property bool dashboardMediaGifEnabled: true
            property string dashboardMediaGifPath: ""
            property real dashboardMediaGifSpeed: 1.0
            property string dashboardPanelWidthMode: "auto"
            property int dashboardPanelWidth: 1190
            property string dashboardPanelHeightMode: "auto"
            property int dashboardPanelHeight: 700
            property string userAvatarPath: ""
            property string sidebarNoNotifsImage: ""
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
