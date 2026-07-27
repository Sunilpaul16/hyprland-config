pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Runtime config singleton (JSON-backed). Grouped rather than flat — nested
// JsonObjects nest in the file the same way, so `Config.dashboard.media.gifSpeed`
// reads and writes `dashboard.media.gifSpeed` in config.json
Singleton {
    id: root

    property alias time: adapter.time
    property alias motion: adapter.motion
    property alias bar: adapter.bar
    property alias sidebar: adapter.sidebar
    property alias session: adapter.session
    property alias notifications: adapter.notifications
    property alias wallpaper: adapter.wallpaper
    property alias dashboard: adapter.dashboard

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

            property JsonObject time: JsonObject {
                property bool use12Hour: false // true = 12-hour clock (AM/PM); false = 24-hour
            }

            // Animation timing. Only these two are user-facing — the bezier
            // curves and rounding tokens in Motion.qml are design-system
            // constants, not preferences
            property JsonObject motion: JsonObject {
                property real speed: 1.0     // higher = faster; divides every duration. Clamped to 0.25–4 in Motion.qml
                property bool reduced: false // true = collapse all durations to 0
            }

            property JsonObject bar: JsonObject {
                property int height: 40 // top bar height (px)
            }

            property JsonObject sidebar: JsonObject {
                property string noNotifsImage: "" // notifications empty-state watermark; "" = the bundled assets/dino.png
            }

            property JsonObject session: JsonObject {
                property int autoCloseDuration: 5000 // ms the drawer stays open unhovered before closing itself
            }

            property JsonObject notifications: JsonObject {
                property int toastDismissDuration: 5000 // ms a toast shows before auto-dismissing
            }

            property JsonObject wallpaper: JsonObject {
                // ms after the wallpaper selection settles before the preview is
                // applied — stops a fast scroll through the carousel spawning a
                // switchwall per step
                property int previewDelay: 300
            }

            // Dashboard card sizing (defaults ported from caelestia's Tokens.sizes.dashboard)
            property JsonObject dashboard: JsonObject {
                // Panel size — "auto" measures/fills as today; "fixed" uses the
                // paired pixel value, clamped to 95% of screen size as a ceiling
                property JsonObject panel: JsonObject {
                    property string widthMode: "auto"  // "auto" | "fixed"
                    property int width: 1190           // px, used only when widthMode is "fixed"
                    property string heightMode: "auto" // "auto" | "fixed"
                    property int height: 700           // px, used only when heightMode is "fixed"
                }

                property JsonObject user: JsonObject {
                    property int width: 340
                    // Absolute, ~-rooted or repo-relative image path; "" falls
                    // back to ~/.face then the bundled bongocat
                    property string avatarPath: ""
                    property int avatarSize: 96
                    property int logoSize: 30   // distro logo badge glyph size (px)
                    property int uptimeSize: 30 // uptime badge diameter (px)
                }

                property JsonObject clock: JsonObject {
                    property int width: 110
                    property int fontSize: 42 // hour/minute glyph size (px)
                }

                property JsonObject weather: JsonObject {
                    property int width: 275
                    property int iconSize: 64 // condition glyph size (px)
                    property int tempSize: 38 // temperature text size (px)
                }

                property JsonObject media: JsonObject {
                    property int cardWidth: 200       // Dashboard tab: condensed Media card
                    property int coverArtSize: 200    // Media tab: cover art side length (px)
                    property int progressThickness: 6 // playback progress arc stroke width (px)
                    property int progressSweep: 180   // progress arc span in degrees (180 = half-circle)
                    // Animated gif (caelestia's bongocat). Empty path = the
                    // repo's bundled assets/bongocat.gif
                    property bool gifEnabled: true
                    property string gifPath: ""
                    property real gifSpeed: 1.0 // playback rate multiplier (1.0 = native)
                }

                property JsonObject resourceRing: JsonObject {
                    property int thickness: 6 // CPU/Memory/Disk ring stroke width (px)
                    property int size: 64     // max ring diameter (px)
                }
            }
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
