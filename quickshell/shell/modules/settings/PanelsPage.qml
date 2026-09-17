import QtQuick
import "../../services"
import "../../components"

// Panels page
ScrollPage {
    id: root

    property string sectionKey: "all"
    property string pageTitle: "Desktop & panels"

    title: root.pageTitle

    function shows(key: string): bool {
        return root.sectionKey === "all" || root.sectionKey === key;
    }

    readonly property int visibleTabCount: (Config.dashboard.tabs.showDashboard ? 1 : 0)
        + (Config.dashboard.tabs.showMedia ? 1 : 0)
        + (Config.dashboard.tabs.showPerformance ? 1 : 0)
        + (Config.dashboard.tabs.showWeather ? 1 : 0)

    // Tab visibility guard
    function setTabVisible(key: string, id: string, on: bool): void {
        if (!on && root.visibleTabCount <= 1)
            return;
        Config.dashboard.tabs[key] = on;
        if (!on && Config.dashboard.panel.defaultTab === id)
            Config.dashboard.panel.defaultTab = root.firstVisibleTabId();
    }

    function firstVisibleTabId(): string {
        if (Config.dashboard.tabs.showDashboard)
            return "dashboard";
        if (Config.dashboard.tabs.showMedia)
            return "media";
        if (Config.dashboard.tabs.showPerformance)
            return "performance";
        return "weather";
    }

    SectionLabel {
        visible: root.shows("behaviour")
        text: "Motion"
    }

    SettingGroup {
        visible: root.shows("behaviour")
        SettingRow {
            first: true
            live: true
            label: "Animation speed"
            subtext: "Divides every duration in the shell"

            NumberControl {
                value: Config.motion.speed
                from: 0.5
                to: 2
                stepSize: 0.05
                decimals: 2
                suffix: "×"
                onMoved: v => Config.motion.speed = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Reduce motion"
            subtext: "Collapses all animation durations to zero"

            ToggleSwitch {
                checked: Config.motion.reduced
                onToggled: value => Config.motion.reduced = value
            }
        }
    }

    SectionLabel {
        visible: root.shows("bar")
        text: "Bar"
    }

    SettingGroup {
        visible: root.shows("bar")
        SettingRow {
            first: true
            live: true
            label: "Bar height"
            subtext: "Height of the top bar"

            NumberControl {
                value: Config.bar.height
                from: 24
                to: 64
                stepSize: 1
                suffix: " px"
                onMoved: v => Config.bar.height = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "12-hour clock"
            subtext: "Show AM/PM instead of 24-hour time"

            ToggleSwitch {
                checked: Config.time.use12Hour
                onToggled: v => Config.time.use12Hour = v
            }
        }

        SettingRow {
            live: true
            label: "Show system tray"

            ToggleSwitch {
                checked: Config.bar.showTray
                onToggled: v => Config.bar.showTray = v
            }
        }

        SettingRow {
            live: true
            label: "Show active window title"

            ToggleSwitch {
                checked: Config.bar.showWindowTitle
                onToggled: v => Config.bar.showWindowTitle = v
            }
        }

        SettingRow {
            live: true
            label: "Auto-hide"
            subtext: "Slide the bar away until the top edge is hovered"

            ToggleSwitch {
                checked: Config.bar.autoHide.enable
                onToggled: v => Config.bar.autoHide.enable = v
            }
        }

        SettingRow {
            live: true
            label: "Push windows on reveal"
            subtext: "Reserve space for the bar while it is revealed"

            ToggleSwitch {
                checked: Config.bar.autoHide.pushWindows
                onToggled: v => Config.bar.autoHide.pushWindows = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Tray items"
            subtext: "Choose which applets appear in the tray pill"

            PillButton {
                live: true
                text: "Edit"
                onClicked: SettingsState.openSubPage("tray")
            }
        }
    }

    SectionLabel {
        visible: root.shows("bar")
        text: "Bar scrolling"
    }

    SettingGroup {
        visible: root.shows("bar")
        SettingRow {
            first: true
            live: true
            // Run end
            last: !Config.bar.scroll.workspaces
            label: "Scroll to switch workspaces"
            subtext: "Wheel over the workspaces pill moves to the next or previous workspace"

            ToggleSwitch {
                checked: Config.bar.scroll.workspaces
                onToggled: v => Config.bar.scroll.workspaces = v
            }
        }

        SettingRow {
            live: true
            visible: Config.bar.scroll.workspaces
            label: "Workspace scroll hint"
            subtext: "Arrows and glyph beside the pill while it is hovered"

            ToggleSwitch {
                checked: Config.bar.scroll.workspacesHint
                onToggled: v => Config.bar.scroll.workspacesHint = v
            }
        }

        SettingRow {
            live: true
            // Run end
            last: !Config.bar.scroll.volume
            label: "Scroll to change volume"
            subtext: "Wheel over the empty bar area between the clock and the workspaces"

            ToggleSwitch {
                checked: Config.bar.scroll.volume
                onToggled: v => Config.bar.scroll.volume = v
            }
        }

        SettingRow {
            last: true
            live: true
            visible: Config.bar.scroll.volume
            label: "Volume scroll hint"
            subtext: "Arrows and glyph in the scroll area while it is hovered"

            ToggleSwitch {
                checked: Config.bar.scroll.volumeHint
                onToggled: v => Config.bar.scroll.volumeHint = v
            }
        }
    }

    SectionLabel {
        visible: root.shows("dashboard")
        text: "Dashboard"
    }

    SettingGroup {
        visible: root.shows("dashboard")
        SettingRow {
            first: true
            live: true
            label: "Panel width"
            subtext: "Auto measures the content; fixed uses a set size"

            SelectPill {
                options: [{ value: "auto", label: "Auto" }, { value: "fixed", label: "Fixed" }]
                current: Config.dashboard.panel.widthMode
                onSelected: v => Config.dashboard.panel.widthMode = v
            }
        }

        SettingRow {
            live: true
            label: "Panel height"
            subtext: "Auto measures the content; fixed uses a set size"

            SelectPill {
                options: [{ value: "auto", label: "Auto" }, { value: "fixed", label: "Fixed" }]
                current: Config.dashboard.panel.heightMode
                onSelected: v => Config.dashboard.panel.heightMode = v
            }
        }

        SettingRow {
            live: true
            label: "Default tab"
            subtext: "Tab a fresh open lands on"

            SelectPill {
                // Shown tabs only
                options: [
                    { value: "dashboard", label: "Dashboard", shown: Config.dashboard.tabs.showDashboard },
                    { value: "media", label: "Media", shown: Config.dashboard.tabs.showMedia },
                    { value: "performance", label: "Performance", shown: Config.dashboard.tabs.showPerformance },
                    { value: "weather", label: "Weather", shown: Config.dashboard.tabs.showWeather }
                ].filter(o => o.shown)
                current: Config.dashboard.panel.defaultTab
                onSelected: v => Config.dashboard.panel.defaultTab = v
            }
        }

        SettingRow {
            live: true
            label: "Media card animation"
            subtext: "The bongocat gif on the dashboard's Media card"

            ToggleSwitch {
                checked: Config.dashboard.media.gifEnabled
                onToggled: v => Config.dashboard.media.gifEnabled = v
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Animation speed"
            subtext: "Gif playback rate (1.00 is native)"

            NumberControl {
                value: Config.dashboard.media.gifSpeed
                from: 0.25
                to: 3
                stepSize: 0.05
                decimals: 2
                suffix: "×"
                onMoved: v => Config.dashboard.media.gifSpeed = v
            }
        }
    }

    SectionLabel {
        visible: root.shows("dashboard")
        text: "Dashboard tabs"
    }

    SettingGroup {
        visible: root.shows("dashboard")
        SettingRow {
            first: true
            live: true
            label: "Dashboard"
            subtext: "Clock, user, weather, media and resource cards"

            ToggleSwitch {
                checked: Config.dashboard.tabs.showDashboard
                onToggled: v => root.setTabVisible("showDashboard", "dashboard", v)
            }
        }

        SettingRow {
            live: true
            label: "Media"
            subtext: "Now playing, cover art and seek bar"

            ToggleSwitch {
                checked: Config.dashboard.tabs.showMedia
                onToggled: v => root.setTabVisible("showMedia", "media", v)
            }
        }

        SettingRow {
            live: true
            label: "Performance"
            subtext: "CPU, memory, network and battery"

            ToggleSwitch {
                checked: Config.dashboard.tabs.showPerformance
                onToggled: v => root.setTabVisible("showPerformance", "performance", v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Weather"
            subtext: "Forecast and conditions. The last remaining tab can't be hidden"

            ToggleSwitch {
                checked: Config.dashboard.tabs.showWeather
                onToggled: v => root.setTabVisible("showWeather", "weather", v)
            }
        }
    }

    SectionLabel {
        visible: root.shows("launcher")
        text: "Launcher"
    }

    SettingGroup {
        visible: root.shows("launcher")
        SettingRow {
            first: true
            live: true
            label: "Fuzzy matching"
            subtext: "Off matches plain substrings only"

            ToggleSwitch {
                checked: Config.launcher.fuzzy
                onToggled: v => Config.launcher.fuzzy = v
            }
        }

        SettingRow {
            live: true
            label: "Panel width"
            subtext: "Apps, commands and clipboard"

            NumberControl {
                value: Config.launcher.panelWidth
                from: 320
                to: 900
                stepSize: 10
                suffix: " px"
                onMoved: v => Config.launcher.panelWidth = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Wallpaper panel width"
            subtext: "Wider, for the horizontal carousel"

            NumberControl {
                value: Config.launcher.wallpaperPanelWidth
                from: 600
                to: 1600
                stepSize: 20
                suffix: " px"
                onMoved: v => Config.launcher.wallpaperPanelWidth = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Favour frequently used"
            subtext: "How hard launch history lifts a result; 0 ranks by match only"

            SettingSlider {
                value: Config.launcher.frequencyWeight
                from: 0
                to: 1
                stepSize: 0.05
                onMoved: v => Config.launcher.frequencyWeight = Math.round(v * 20) / 20
            }
        }

        SettingRow {
            live: true
            label: "Maximum results"
            subtext: "App and command rows shown at once"

            NumberControl {
                value: Config.launcher.maxResults
                from: 3
                to: 20
                stepSize: 1
                onMoved: v => Config.launcher.maxResults = Math.round(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Clipboard results"
            subtext: "Clipboard rows shown at once"

            NumberControl {
                value: Config.launcher.maxClipResults
                from: 3
                to: 20
                stepSize: 1
                onMoved: v => Config.launcher.maxClipResults = Math.round(v)
            }
        }
    }

    SectionLabel {
        visible: root.shows("sidebar")
        text: "Sidebar"
    }

    SettingGroup {
        visible: root.shows("sidebar")
        SettingRow {
            first: true
            live: true
            label: "Sidebar width"

            NumberControl {
                value: Config.sidebar.width
                from: 280
                to: 640
                stepSize: 10
                suffix: " px"
                onMoved: v => Config.sidebar.width = Math.round(v)
            }
        }

        SettingRow {
            live: true
            label: "Quick toggles"
            subtext: "Show, hide, reorder and resize the sidebar pills"

            PillButton {
                live: true
                text: "Edit"
                onClicked: SettingsState.openSubPage("quickToggles")
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Close when settings opens"

            ToggleSwitch {
                checked: Config.sidebar.closeOnSettings
                onToggled: v => Config.sidebar.closeOnSettings = v
            }
        }
    }

    SectionLabel {
        visible: root.shows("behaviour")
        text: "Overview & session"
    }

    // No live-thumbnail toggle
    SettingGroup {
        visible: root.shows("behaviour")
        SettingRow {
            first: true
            last: true
            live: true
            label: "Session drawer auto-close"
            subtext: "How long the drawer stays open unhovered"

            NumberControl {
                value: Config.session.autoCloseDuration
                from: 1000
                to: 15000
                stepSize: 500
                suffix: " ms"
                onMoved: v => Config.session.autoCloseDuration = Math.round(v)
            }
        }
    }
}
