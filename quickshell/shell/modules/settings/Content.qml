import QtQuick
import "../../services"
import "../../components"

// Settings content
Item {
    id: root

    property bool panelActive: false

    readonly property int pad: 18
    readonly property int navWidth: Math.min(Config.settings.navWidth, Math.round(width * 0.4))

    // Natural height
    readonly property int naturalHeight: navList.naturalHeight + root.pad * 2

    // Page registry
    readonly property var pageModel: [
        // Appearance
        { key: "wallpaperStyle", label: "Wallpaper & style", icon: "palette", description: "Wallpaper, fonts, colours", keywords: "theme transparency opacity blur palette scheme qt terminal", category: "appearance", component: wallpaperStylePage },
        { key: "ambient", label: "Ambient desktop", icon: "landscape", description: "Time, weather and wallpaper atmosphere", keywords: "sunrise sunset dawn dusk night tint weather battery focus", category: "appearance", component: ambientPage },

        // Shell
        { key: "panels", label: "Panels", icon: "dock_to_bottom", description: "Dashboard, taskbar, launcher, sidebar", keywords: "bar animation motion tabs tray clock osd", category: "shell", component: panelsPage },
        { key: "overlay", label: "Overlay widgets", icon: "widgets", description: "Crosshair, notes, floating image", keywords: "aim reticle picture", category: "shell", component: overlayPage },
        { key: "services", label: "Services", icon: "build", description: "Poll intervals, notifications", keywords: "weather recorder night light polling toast", category: "shell", component: servicesPage },

        // System
        { key: "audio", label: "Audio", icon: "volume_up", description: "App volumes, sound devices", keywords: "speaker microphone mute boost osd sink source", category: "system", component: audioPage },
        { key: "updates", label: "Updates", icon: "update", description: "System updates", keywords: "aur yay packages upgrade notifications", category: "system", component: updatesPage },

        // Connectivity
        { key: "idlePower", label: "Idle & power", icon: "bedtime", description: "Lock, displays, suspend", keywords: "sleep dpms timeout inhibit awake", category: "connectivity", component: idlePowerPage },
        { key: "network", label: "Network", icon: "lan", description: "Ethernet, VPN, usage", keywords: "nordvpn throughput download upload connection", category: "connectivity", component: networkPage },
        { key: "connectedDevices", label: "Connected devices", icon: "devices_other", description: "Bluetooth, pairing", keywords: "scan discoverable connect", category: "connectivity", component: connectedDevicesPage },

        // About
        { key: "about", label: "About", icon: "info", description: "System information, credits", keywords: "hardware processor memory gpu kernel restart shell github", category: "about", component: aboutPage }
    ]

    // Sub-page registry
    readonly property var subPageModel: ({
        "wallpapers": wallpapersSubPage,
        "schemes": schemesSubPage,
        "tray": traySubPage,
        "quickToggles": quickTogglesSubPage
    })

    // Resolve deep link
    function resolvePendingPage(): void {
        if (!SettingsState.pendingPage)
            return;
        const idx = root.pageModel.findIndex(p => p.key === SettingsState.pendingPage);
        SettingsState.pendingPage = "";
        if (idx >= 0)
            SettingsState.currentPageIdx = idx;
    }

    Component.onCompleted: root.resolvePendingPage()

    Connections {
        target: SettingsState
        function onPendingPageChanged() {
            root.resolvePendingPage();
        }
    }

    NavList {
        id: navList

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: root.pad
        width: root.navWidth

        pageModel: root.pageModel
        panelActive: root.panelActive
    }

    // Page area
    Item {
        id: pageArea

        anchors.left: navList.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad + 8
        anchors.topMargin: root.pad + 8
        anchors.bottomMargin: root.pad

        // Rendered index
        property int shownIdx: 0
        // Slide direction
        property real slideFrom: 0

        readonly property var page: root.pageModel[shownIdx] ?? root.pageModel[0]
        // Shown sub-page
        property string shownSubPage: ""
        readonly property var subComponent: root.subPageModel[pageArea.shownSubPage] ?? null

        Loader {
            id: pageLoader

            width: pageArea.width
            height: pageArea.height

            sourceComponent: pageArea.subComponent ?? pageArea.page.component ?? placeholderPage
        }

        // Sub-page animation
        Connections {
            target: SettingsState
            function onSubPageChanged() {
                switchAnim.complete();
                pageArea.slideFrom = SettingsState.subPage ? 18 : -18;
                subSwitchAnim.start();
            }
        }

        Connections {
            target: SettingsState
            function onCurrentPageIdxChanged() {
                // Clamp on singleton
                const clamped = Math.max(0, Math.min(SettingsState.currentPageIdx, root.pageModel.length - 1));
                if (clamped !== SettingsState.currentPageIdx) {
                    SettingsState.currentPageIdx = clamped;
                    return;
                }

                switchAnim.complete();
                pageArea.slideFrom = clamped > pageArea.shownIdx ? 18 : -18;
                switchAnim.start();
            }
        }

        SequentialAnimation {
            id: subSwitchAnim

            NumberAnimation {
                target: pageLoader
                property: "opacity"
                to: 0
                duration: Motion.scaled(45)
                easing.type: Motion.quickEasing
            }
            PropertyAction {
                target: pageArea
                property: "shownSubPage"
                value: SettingsState.subPage
            }
            PropertyAction {
                target: pageLoader
                property: "y"
                value: pageArea.slideFrom
            }
            ParallelAnimation {
                NumberAnimation {
                    target: pageLoader
                    property: "opacity"
                    to: 1
                    duration: Motion.deliberateDuration
                    easing.type: Motion.deliberateEasing
                }
                NumberAnimation {
                    target: pageLoader
                    property: "y"
                    to: 0
                    duration: Motion.deliberateDuration
                    easing.type: Motion.deliberateEasing
                }
            }
        }

        SequentialAnimation {
            id: switchAnim

            NumberAnimation {
                target: pageLoader
                property: "opacity"
                to: 0
                duration: Motion.scaled(45)
                easing.type: Motion.quickEasing
            }
            PropertyAction {
                target: pageArea
                property: "shownIdx"
                value: SettingsState.currentPageIdx
            }
            PropertyAction {
                target: pageLoader
                property: "y"
                value: pageArea.slideFrom
            }
            ParallelAnimation {
                NumberAnimation {
                    target: pageLoader
                    property: "opacity"
                    to: 1
                    duration: Motion.deliberateDuration
                    easing.type: Motion.deliberateEasing
                }
                NumberAnimation {
                    target: pageLoader
                    property: "y"
                    to: 0
                    duration: Motion.deliberateDuration
                    easing.type: Motion.deliberateEasing
                }
            }
        }
    }

    // Close button
    IconAction {
        id: closeButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Motion.spacing.medium
        implicitWidth: 30
        implicitHeight: 30
        radius: width / 2
        iconName: "close"
        iconSize: Motion.fontSize.header
        iconColor: closeButton.hovered ? Colors.error : Colors.textMuted
        onTriggered: SettingsState.open = false
    }

    // Sub-pages
    Component {
        id: wallpapersSubPage

        WallpapersSubPage {}
    }

    Component {
        id: schemesSubPage

        SchemesSubPage {}
    }

    Component {
        id: traySubPage

        TraySubPage {}
    }

    Component {
        id: quickTogglesSubPage

        QuickTogglesSubPage {}
    }

    // Pages
    Component {
        id: wallpaperStylePage

        WallpaperStylePage {}
    }

    Component {
        id: ambientPage

        AmbientPage {}
    }

    Component {
        id: networkPage

        NetworkPage {}
    }

    Component {
        id: connectedDevicesPage

        ConnectedDevicesPage {}
    }

    Component {
        id: audioPage

        AudioPage {}
    }

    Component {
        id: updatesPage

        UpdatesPage {}
    }

    Component {
        id: idlePowerPage

        IdlePowerPage {}
    }

    Component {
        id: panelsPage

        PanelsPage {}
    }

    Component {
        id: overlayPage

        OverlayPage {}
    }

    Component {
        id: servicesPage

        ServicesPage {}
    }

    Component {
        id: aboutPage

        AboutPage {}
    }

    // Placeholder page
    Component {
        id: placeholderPage

        PlaceholderPage {
            title: pageArea.page.label
        }
    }
}
