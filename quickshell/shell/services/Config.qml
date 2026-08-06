pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Runtime config singleton
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
    property alias overlay: adapter.overlay

    // Load gate
    property bool ready: false

    // Parse failure guard
    property bool fileValid: true

    onFileValidChanged: {
        if (!root.fileValid) {
            console.warn("[Config] config.json did not parse — running on defaults, and no config write will touch the file until it does");
            invalidToastTimer.restart();
        }
    }

    // Validate document
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

        // Clear on reload
        onLoaded: {
            root.validate();
            root.ready = true;
        }
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            else
                console.warn("[Config] could not read config.json — running on defaults");
            // Defaults beat no desktop
            root.ready = true;
        }

        // Persisted values
        JsonAdapter {
            id: adapter

            property JsonObject time: JsonObject {
                property bool use12Hour: false  // 12-hour clock
            }

            // Animation timing
            property JsonObject motion: JsonObject {
                property real speed: 1.0  // higher = faster
                property bool reduced: false  // no animations
            }

            property JsonObject bar: JsonObject {
                property int height: 40  // bar height (px)
                property bool showTray: true        // system tray pill
                property bool showWindowTitle: true // active-window pill
                // Hidden tray ids
                property string trayHidden: "nm-applet,blueman"
                // Slide off-screen until hovered
                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                    property bool pushWindows: false  // reserve space when revealed
                }
                // Wheel gestures
                property JsonObject scroll: JsonObject {
                    property bool workspaces: true      // wheel switches workspace
                    property bool workspacesHint: true  // swap_horiz glyph
                    property bool volume: true          // wheel changes volume
                    property bool volumeHint: true      // volume_up glyph
                }
            }

            property JsonObject sidebar: JsonObject {
                property string noNotifsImage: ""  // empty-state watermark
                property bool calendarCollapsed: false  // calendar starts collapsed
                property bool closeOnSettings: true  // close on settings
                property int width: 360             // drawer width
            }

            property JsonObject session: JsonObject {
                property int autoCloseDuration: 5000  // auto-close ms
                property bool keepAwakeDefault: false  // inhibit from start
            }

            // Idle timeouts (seconds)
            property JsonObject idle: JsonObject {
                property int lockTimeout: 900  // lock after idle
                property int dpmsTimeout: 1800  // displays off
                property int suspendTimeout: 3600  // suspend
                property bool inhibitWhenAudio: true  // media suppresses idle
            }

            property JsonObject overlay: JsonObject {
                property bool darkenScreen: true  // scrim while editing
                property JsonObject floatingImage: JsonObject {
                    property string source: "assets/bongocat.gif"  // image or gif path
                    property real scale: 1.0
                }
                property JsonObject crosshair: JsonObject {
                    property string color: "#00ff66"
                    property real opacity: 0.85
                    property int gap: 6  // centre to line
                    property int length: 8
                    property int thickness: 2
                    property bool outline: true
                    property bool centerDot: true
                    property int dotSize: 2
                }
            }

            property JsonObject notifications: JsonObject {
                property int toastDismissDuration: 5000  // toast timeout ms
                property bool keepAcrossRestarts: true  // persist history to disk
                property int historyLimit: 200  // newest kept on disk
                property int groupPreviewNum: 3  // collapsed group size
                property real swipeThreshold: 0.3  // swipe dismiss fraction
                property string fullscreen: "on"  // "on" | "off"
                property int fullscreenExpireDuration: 2000  // fullscreen toast ms
                property string popupPosition: "top-right" // "top-right" | "top-left" | "bottom-right" | "bottom-left"
            }

            // External programs
            property JsonObject apps: JsonObject {
                // Terminal emulator
                property string terminal: "kitty"
            }

            property JsonObject updates: JsonObject {
                property bool autoCheck: true  // check on start
                property int intervalMinutes: 360  // minutes, min 15
                property string aurHelper: "yay"  // AUR helper (-Qua)
                property bool notify: true  // notify on growth
                property bool showInBar: false  // bar pill
            }

            // Poll intervals (ms)
            property JsonObject polling: JsonObject {
                property int cpu: 1000
                property int gpu: 2000
                property int storage: 10000
                property int uptime: 60000
                property int networkStatus: 5000 // ethernet link + VPN state
                property int networkUsage: 1000  // network throughput
            }

            property JsonObject weather: JsonObject {
                property string units: "celsius" // "celsius" | "fahrenheit"
                property int refreshMinutes: 60
            }

            // Appearance
            property JsonObject appearance: JsonObject {
                property bool transparency: false
                property real panelOpacity: 0.85  // panel opacity
                property real layerOpacity: 0.55  // layer opacity
                property real pillOpacity: 0.55   // bar pill opacity
                // Fonts
                property string fontInterface: "Noto Sans"  // shell text
                property string fontGlyph: "JetBrainsMono Nerd Font"  // icon glyphs
            }

            // Settings panel size
            property JsonObject settings: JsonObject {
                property int maxContentWidth: 800 // page content column
                property int navWidth: 340        // left nav pane
                property real heightMult: 0.8  // max screen fraction
            }

            // Read by switchwall
            property JsonObject theming: JsonObject {
                property string scheme: "auto"  // "auto" | "scheme-*"
                property real terminalHarmony: 0.8
                property int terminalHarmonizeThreshold: 100
                property real terminalFgBoost: 0.35
                property bool terminalForceDark: false
                property real terminalOpacity: 1.0  // kitty opacity
            }

            property JsonObject nightLight: JsonObject {
                property int temperature: 5200  // colour temperature
                property bool schedule: true  // auto schedule
                // Local hours, 0-23
                property int startHour: 19
                property int endHour: 7
            }

            property JsonObject recorder: JsonObject {
                property string defaultMode: "full"  // "full" | "region"
                property bool audio: false  // record audio
            }

            property JsonObject launcher: JsonObject {
                property int maxResults: 8  // app rows
                property int maxClipResults: 6  // clipboard rows
                property bool fuzzy: true  // fuzzy matching
                property real frequencyWeight: 0.3  // history weight
                property string searchPrefix: "@"  // field prefix
                property int panelWidth: 460  // panel width
                property int wallpaperPanelWidth: 900  // carousel width
            }

            property JsonObject audio: JsonObject {
                property real volumeStep: 0.05  // step fraction
                property bool unmuteOnChange: true // raising volume clears mute
                property bool allowBoost: false  // allow boost
                property bool osdEnabled: true  // show OSD
                property int osdTimeout: 1500  // OSD timeout ms
                property string osdEdge: "right"  // "right" | "left"
            }

            property JsonObject wallpaper: JsonObject {
                // Preview debounce
                property int previewDelay: 300
                property bool display: true  // enable mpvpaper
            }

            // Dashboard card sizing
            property JsonObject dashboard: JsonObject {
                // Panel size
                property JsonObject panel: JsonObject {
                    property string widthMode: "auto"  // "auto" | "fixed"
                    property int width: 1190  // px, fixed mode only
                    property string heightMode: "auto" // "auto" | "fixed"
                    property int height: 700  // px, fixed mode only
                    // Default tab
                    property string defaultTab: "dashboard" // "dashboard" | "media" | "performance" | "weather"
                }

                // Tab visibility
                property JsonObject tabs: JsonObject {
                    property bool showDashboard: true
                    property bool showMedia: true
                    property bool showPerformance: true
                    property bool showWeather: true
                }

                property JsonObject user: JsonObject {
                    property int width: 340
                    // Avatar path
                    property string avatarPath: ""
                    property int avatarSize: 96
                    property int logoSize: 30  // logo size (px)
                    property int uptimeSize: 30  // uptime badge (px)
                }

                property JsonObject clock: JsonObject {
                    property int width: 110
                    property int fontSize: 42  // clock size (px)
                }

                property JsonObject weather: JsonObject {
                    property int width: 275
                    property int iconSize: 64  // icon size (px)
                    property int tempSize: 38  // temp size (px)
                }

                property JsonObject media: JsonObject {
                    property int cardWidth: 200  // condensed media card
                    property int coverArtSize: 200  // cover art (px)
                    property int progressThickness: 6  // arc stroke (px)
                    property int progressSweep: 180  // arc span degrees
                    // Animated gif
                    property bool gifEnabled: true
                    property string gifPath: ""
                    property real gifSpeed: 1.0  // playback rate
                }

                property JsonObject resourceRing: JsonObject {
                    property int thickness: 6  // ring stroke (px)
                    property int size: 64  // ring diameter (px)
                }
            }
        }
    }

    // Undeclared keys
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

    // Merge preserved keys
    function mergeInto(base, extras) {
        for (const key in extras) {
            if (root.isPlainObject(extras[key]) && root.isPlainObject(base[key]))
                root.mergeInto(base[key], extras[key]);
            else
                base[key] = extras[key];
        }
        return base;
    }

    // Write preserving unknown
    function writePreservingUnknown(): void {
        // Refuse writing defaults
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

    // Delayed toast
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
