pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Runtime config singleton (JSON-backed), grouped rather than flat — `Config.dashboard.media.gifSpeed` reads and writes `dashboard.media.gifSpeed`
Singleton {
    id: root

    property alias time: adapter.time
    property alias motion: adapter.motion
    property alias bar: adapter.bar
    property alias sidebar: adapter.sidebar
    property alias session: adapter.session
    property alias notifications: adapter.notifications
    property alias updates: adapter.updates
    property alias polling: adapter.polling
    property alias weather: adapter.weather
    property alias nightLight: adapter.nightLight
    property alias theming: adapter.theming
    property alias appearance: adapter.appearance
    property alias settings: adapter.settings
    property alias recorder: adapter.recorder
    property alias launcher: adapter.launcher
    property alias audio: adapter.audio
    property alias wallpaper: adapter.wallpaper
    property alias dashboard: adapter.dashboard
    property alias apps: adapter.apps
    property alias idle: adapter.idle

    // Gates panels from reading config before the FileView has loaded
    property bool ready: false

    // False while the file exists but doesn't parse. JsonAdapter only warns on a malformed
    // document and keeps its declared defaults, so the shell runs normally and the next write
    // would replace the real file with those defaults — every customised value and every
    // unknown key gone. Writing is refused until it parses again
    property bool fileValid: true

    onFileValidChanged: {
        if (!root.fileValid) {
            console.warn("[Config] config.json did not parse — running on defaults, and no config write will touch the file until it does");
            invalidToastTimer.restart();
        }
    }

    // JsonAdapter bails on both a parse error and a valid non-object document, so check for each
    function validate(): void {
        const text = configFile.text();
        if (text.trim().length === 0) {
            root.fileValid = true;
            return;
        }
        try {
            root.fileValid = root.isPlainObject(JSON.parse(text));
        } catch (e) {
            root.fileValid = false;
        }
    }

    // Config file
    FileView {
        id: configFile
        path: Directories.configFile
        watchChanges: true

        // Re-runs on every reload too, so fixing the file clears the flag without a restart
        onLoaded: {
            root.validate();
            root.ready = true;
        }
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

            // Animation timing — only these two are user-facing; Motion.qml's curves and rounding tokens are design constants, not preferences
            property JsonObject motion: JsonObject {
                property real speed: 1.0     // higher = faster; divides every duration. Clamped to 0.25–4 in Motion.qml
                property bool reduced: false // true = collapse all durations to 0
            }

            property JsonObject bar: JsonObject {
                property int height: 40 // top bar height (px)
                property bool showTray: true        // system tray pill
                property bool showWindowTitle: true // active-window pill
                // Tray item ids kept out of the pill — status applets with no user-facing app. Comma-separated, matched case-insensitively against SystemTrayItem.id
                // A string, not a list: JsonAdapter only serialises QQmlListProperty<JsonObject>, so a `list<string>` is silently dropped on write (jsonadapter.cpp:75/118)
                property string trayHidden: "nm-applet,blueman"
            }

            property JsonObject sidebar: JsonObject {
                property string noNotifsImage: "" // notifications empty-state watermark; "" = the bundled assets/dino.png
                property bool calendarCollapsed: false // sidebar calendar card starts collapsed
                property bool closeOnSettings: true // close the sidebar when settings opens
                property int width: 360             // drawer width
            }

            property JsonObject session: JsonObject {
                property int autoCloseDuration: 5000 // ms the drawer stays open unhovered before closing itself
                property bool keepAwakeDefault: false // hold the idle inhibitor from shell start
            }

            // Idle timeouts in seconds, 0 meaning never. Defaults match the listener blocks
            // hypridle.conf used to own; its general{} block still handles the logind side
            property JsonObject idle: JsonObject {
                property int lockTimeout: 900     // lock the screen after this long idle
                property int dpmsTimeout: 1800    // turn the displays off after this long idle
                property int suspendTimeout: 3600 // suspend the machine after this long idle
                property bool inhibitWhenAudio: true // a playing MPRIS player suppresses all of the above
            }

            property JsonObject notifications: JsonObject {
                property int toastDismissDuration: 5000 // ms a toast shows before auto-dismissing
                property bool keepAcrossRestarts: true  // persist history to disk
                property int groupPreviewNum: 3         // newest N shown in a collapsed app group
                property real swipeThreshold: 0.3       // fraction of card width a swipe must cross to dismiss
                property string fullscreen: "on"        // toasts over a fullscreen window: "on" (brief) | "off" (suppressed)
                property int fullscreenExpireDuration: 2000 // ms a toast shows while a window is fullscreen
                property string popupPosition: "top-right" // "top-right" | "top-left" | "bottom-right" | "bottom-left"
            }

            // External programs the shell launches on the user's behalf
            property JsonObject apps: JsonObject {
                // Used for desktop entries marked Terminal=true and for the upgrade runner. The exec flag is assumed to be `-e`, which covers kitty/foot/alacritty/ghostty
                property string terminal: "kitty"
            }

            property JsonObject updates: JsonObject {
                property bool autoCheck: true       // query for updates on start and on the interval below
                property int intervalMinutes: 360   // floored at 15 in Updates.qml
                property string aurHelper: "yay"    // any helper supporting -Qua ("yay" | "paru" | ...)
                property bool notify: true     // desktop notification when the pending count grows
                property bool showInBar: false // pending-count pill in the bar
            }

            // Poll intervals in ms for the refcounted stat services
            property JsonObject polling: JsonObject {
                property int cpu: 1000
                property int gpu: 2000
                property int storage: 10000
                property int uptime: 60000
                property int networkStatus: 5000 // ethernet link + VPN state
                property int networkUsage: 1000  // /proc/net/dev throughput sampling
            }

            property JsonObject weather: JsonObject {
                property string units: "celsius" // "celsius" | "fahrenheit"
                property int refreshMinutes: 60
            }

            // Translucency applies only to each panel's outermost surface, so nothing compounds and no per-depth model is needed
            property JsonObject appearance: JsonObject {
                property bool transparency: false
                property real panelOpacity: 0.85 // panel backgrounds; used only when transparency is on
                property real layerOpacity: 0.55 // cards and pills on top of a panel
                // Fonts.qml validates families against the installed set and falls back to these, rather than letting Qt silently substitute
                property string fontInterface: "Noto Sans" // all shell text, via StyledText
                property string fontGlyph: "JetBrainsMono Nerd Font" // Nerd Font icon glyphs only
            }

            // Settings panel size — both axes derived from content (nav pane + capped page column, nav list height), not an aspect ratio
            property JsonObject settings: JsonObject {
                property int maxContentWidth: 800 // page content column
                property int navWidth: 340        // left nav pane
                property real heightMult: 0.8     // ceiling only, as a fraction of screen height
            }

            // Read by scripts/switchwall via jq, never by the shell — defaults match generate_colors_material.py's own
            property JsonObject theming: JsonObject {
                property string scheme: "auto" // "auto" (picked from the image) | any scheme-* the generator supports
                property real terminalHarmony: 0.8
                property int terminalHarmonizeThreshold: 100
                property real terminalFgBoost: 0.35
                property bool terminalForceDark: false
                property real terminalOpacity: 1.0 // kitty window opacity; 1 = solid
            }

            property JsonObject nightLight: JsonObject {
                property int temperature: 5200 // kelvin applied by hyprsunset
                property bool schedule: true   // turn night light on and off automatically
                // Local hours, 0-23. end < start is an overnight window (the default 19->07)
                property int startHour: 19
                property int endHour: 7
            }

            property JsonObject recorder: JsonObject {
                property string defaultMode: "full" // "full" | "region" — mode a fresh session starts in
                property bool audio: false          // capture the default sink's monitor alongside video
            }

            property JsonObject launcher: JsonObject {
                property int maxResults: 8     // app/command rows shown at once
                property int maxClipResults: 6 // clipboard rows shown at once
                property bool fuzzy: true      // subsequence matching; off = plain substring
                property real frequencyWeight: 0.3 // how hard launch history lifts a result; 0 disables ranking entirely
                property string searchPrefix: "@"  // "@e foo" scopes the match to a field; empty disables prefix parsing
                property int panelWidth: 460          // app/command/clipboard panel width
                property int wallpaperPanelWidth: 900 // wider, since the wallpaper carousel is horizontal
            }

            property JsonObject audio: JsonObject {
                property real volumeStep: 0.05    // fraction per increment/decrement
                property bool unmuteOnChange: true // raising volume clears mute
                property bool allowBoost: false   // let the sink exceed unity gain
                property bool osdEnabled: true    // show the volume OSD on change
                property int osdTimeout: 1500     // ms before the OSD auto-hides
                property string osdEdge: "right"  // "right" | "left"
            }

            property JsonObject wallpaper: JsonObject {
                // ms after the selection settles before preview applies — stops a fast carousel scroll spawning a switchwall per step
                property int previewDelay: 300
                property bool display: true    // false kills mpvpaper and shows misc:background_color
            }

            // Dashboard card sizing
            property JsonObject dashboard: JsonObject {
                // Panel size — "auto" measures/fills as today; "fixed" uses the
                // paired pixel value, clamped to 95% of screen size as a ceiling
                property JsonObject panel: JsonObject {
                    property string widthMode: "auto"  // "auto" | "fixed"
                    property int width: 1190           // px, used only when widthMode is "fixed"
                    property string heightMode: "auto" // "auto" | "fixed"
                    property int height: 700           // px, used only when heightMode is "fixed"
                    // Tab a fresh open lands on. An id, not an index, so hiding
                    // a tab can't silently repoint it at a different one
                    property string defaultTab: "dashboard" // "dashboard" | "media" | "performance" | "weather"
                }

                // Which tabs the dashboard offers — a hidden one leaves the bar
                // entirely rather than showing disabled
                property JsonObject tabs: JsonObject {
                    property bool showDashboard: true
                    property bool showMedia: true
                    property bool showPerformance: true
                    property bool showWeather: true
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
                    // Animated gif; empty path = the bundled assets/bongocat.gif
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

    // Keys present on disk but absent from the written schema, i.e. ones this adapter doesn't declare
    function unknownKeys(prior, written) {
        const extras = {};
        for (const key in prior) {
            if (!(key in written)) {
                extras[key] = prior[key];
            } else if (root.isPlainObject(prior[key]) && root.isPlainObject(written[key])) {
                const nested = root.unknownKeys(prior[key], written[key]);
                if (Object.keys(nested).length > 0)
                    extras[key] = nested;
            }
        }
        return extras;
    }

    function isPlainObject(v): bool {
        return v !== null && typeof v === "object" && !Array.isArray(v);
    }

    // Folds preserved keys back into the freshly written document
    function mergeInto(base, extras) {
        for (const key in extras) {
            if (root.isPlainObject(extras[key]) && root.isPlainObject(base[key]))
                root.mergeInto(base[key], extras[key]);
            else
                base[key] = extras[key];
        }
        return base;
    }

    // JsonAdapter serialises only its declared properties, so a straight writeAdapter() silently
    // drops anything else in the file — re-merge those keys instead of destroying them
    function writePreservingUnknown(): void {
        // The adapter is holding defaults, not the file's values — writing them would be the data loss, not the recovery
        if (!root.fileValid)
            return;

        let prior = null;
        try {
            prior = JSON.parse(configFile.text());
        } catch (e) {
            prior = null;
        }

        configFile.writeAdapter();

        if (prior === null)
            return;

        configFile.waitForJob();

        let written = null;
        try {
            written = JSON.parse(configFile.text());
        } catch (e) {
            return;
        }

        const extras = root.unknownKeys(prior, written);
        if (Object.keys(extras).length === 0)
            return;

        configFile.setText(JSON.stringify(root.mergeInto(written, extras), null, 2) + "\n");
    }

    // Delayed so the toast lands after the notification panel exists — Config loads before any panel does
    Timer {
        id: invalidToastTimer
        interval: 3000
        repeat: false
        onTriggered: Notifs.toast("Config not loaded", "config.json could not be parsed. Running on defaults; the file is left untouched until it is valid.", "settings_alert")
    }

    // Debounced write
    Timer {
        id: writeTimer
        interval: 50
        repeat: false
        onTriggered: root.writePreservingUnknown()
    }

    // Debounced reload
    Timer {
        id: reloadTimer
        interval: 50
        repeat: false
        onTriggered: configFile.reload()
    }
}
