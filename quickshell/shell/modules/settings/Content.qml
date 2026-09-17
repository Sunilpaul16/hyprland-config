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

    // Selected section within grouped destinations
    property int appearanceSection: 0
    property int desktopSection: 0
    property int devicesSection: 0
    property int powerSection: 0
    property int systemSection: 0

    // Primary destinations
    readonly property var pageModel: [
        { key: "appearance", label: "Appearance", icon: "palette", description: "Wallpaper, colours and ambience", keywords: "wallpaper font theme transparency palette weather", category: "personal", component: appearancePage },
        { key: "desktop", label: "Desktop & panels", icon: "dashboard", description: "Bar, dashboard, launcher and overlays", keywords: "sidebar behaviour motion tray crosshair", category: "desktop", component: desktopPage },
        { key: "notifications", label: "Notifications", icon: "notifications", description: "Popups, history and do-not-disturb", keywords: "toast dnd position restart", category: "desktop", component: notificationsPage },
        { key: "devices", label: "Audio & devices", icon: "devices_other", description: "Sound, microphone and Bluetooth", keywords: "speaker volume input output pairing scan", category: "hardware", component: devicesPage },
        { key: "network", label: "Network", icon: "lan", description: "Ethernet, VPN and usage", keywords: "nordvpn throughput download upload connection", category: "hardware", component: networkPage },
        { key: "power", label: "Power & display", icon: "bedtime", description: "Idle, keep awake and night light", keywords: "lock dpms suspend inhibit temperature schedule", category: "hardware", component: powerPage },
        { key: "system", label: "System", icon: "settings", description: "Updates, recording and background activity", keywords: "packages recorder polling cpu gpu storage", category: "system", component: systemPage },
        { key: "about", label: "About", icon: "info", description: "System information and credits", keywords: "hardware processor memory gpu kernel restart shell github", category: "system", component: aboutPage }
    ]

    // Sub-page registry
    readonly property var subPageModel: ({
        "wallpapers": wallpapersSubPage,
        "schemes": schemesSubPage,
        "tray": traySubPage,
        "quickToggles": quickTogglesSubPage
    })

    readonly property var deepLinks: ({
        wallpaperStyle: { page: "appearance", section: 0 },
        ambient: { page: "appearance", section: 2 },
        panels: { page: "desktop", section: 0 },
        overlay: { page: "desktop", section: 4 },
        services: { page: "system", section: 2 },
        audio: { page: "devices", section: 0 },
        connectedDevices: { page: "devices", section: 1 },
        updates: { page: "system", section: 0 },
        idlePower: { page: "power", section: 0 }
    })

    function selectSection(page: string, section: int): void {
        if (page === "appearance")
            root.appearanceSection = section;
        else if (page === "desktop")
            root.desktopSection = section;
        else if (page === "devices")
            root.devicesSection = section;
        else if (page === "power")
            root.powerSection = section;
        else if (page === "system")
            root.systemSection = section;
    }

    // Resolve old and new deep links
    function resolvePendingPage(): void {
        if (!SettingsState.pendingPage)
            return;
        const pending = SettingsState.pendingPage;
        const route = root.deepLinks[pending] ?? { page: pending, section: 0 };
        const idx = root.pageModel.findIndex(p => p.key === route.page);
        SettingsState.pendingPage = "";
        if (idx >= 0) {
            root.selectSection(route.page, route.section);
            SettingsState.currentPageIdx = idx;
        }
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

    // Grouped pages
    Component {
        id: appearancePage

        CategoryPage {
            title: "Appearance"
            currentSection: root.appearanceSection
            onSectionSelected: index => root.appearanceSection = index
            sections: [
                { label: "Wallpaper", icon: "wallpaper", component: appearanceWallpaperPage },
                { label: "Colours & style", icon: "palette", component: appearanceStylePage },
                { label: "Ambient desktop", icon: "landscape", component: ambientPage }
            ]
        }
    }

    Component {
        id: desktopPage

        CategoryPage {
            title: "Desktop & panels"
            currentSection: root.desktopSection
            onSectionSelected: index => root.desktopSection = index
            sections: [
                { label: "Top bar", icon: "dock_to_bottom", component: topBarPage },
                { label: "Dashboard", icon: "dashboard", component: dashboardPage },
                { label: "Launcher", icon: "search", component: launcherPage },
                { label: "Sidebar", icon: "view_sidebar", component: sidebarPage },
                { label: "Overlays", icon: "widgets", component: overlayPage },
                { label: "Behaviour", icon: "animation", component: behaviourPage }
            ]
        }
    }

    Component {
        id: notificationsPage

        ServicesPage {
            sectionKey: "notifications"
            pageTitle: "Notifications"
        }
    }

    Component {
        id: devicesPage

        CategoryPage {
            title: "Audio & devices"
            currentSection: root.devicesSection
            onSectionSelected: index => root.devicesSection = index
            sections: [
                { label: "Audio", icon: "volume_up", component: audioPage },
                { label: "Bluetooth", icon: "bluetooth", component: connectedDevicesPage }
            ]
        }
    }

    Component {
        id: networkPage

        NetworkPage {}
    }

    Component {
        id: powerPage

        CategoryPage {
            title: "Power & display"
            currentSection: root.powerSection
            onSectionSelected: index => root.powerSection = index
            sections: [
                { label: "Idle & power", icon: "bedtime", component: idlePowerPage },
                { label: "Night light", icon: "dark_mode", component: nightLightPage }
            ]
        }
    }

    Component {
        id: systemPage

        CategoryPage {
            title: "System"
            currentSection: root.systemSection
            onSectionSelected: index => root.systemSection = index
            sections: [
                { label: "Updates", icon: "update", component: updatesPage },
                { label: "Screen recording", icon: "screen_record", component: recordingPage },
                { label: "Background activity", icon: "sync", component: pollingPage }
            ]
        }
    }

    // Appearance sections
    Component {
        id: appearanceWallpaperPage

        WallpaperStylePage {
            sectionKey: "wallpaper"
            pageTitle: "Wallpaper"
        }
    }

    Component {
        id: appearanceStylePage

        WallpaperStylePage {
            sectionKey: "style"
            pageTitle: "Colours & style"
        }
    }

    Component {
        id: ambientPage

        AmbientPage {}
    }

    // Desktop sections
    Component {
        id: topBarPage

        PanelsPage { sectionKey: "bar" }
    }

    Component {
        id: dashboardPage

        PanelsPage { sectionKey: "dashboard" }
    }

    Component {
        id: launcherPage

        PanelsPage { sectionKey: "launcher" }
    }

    Component {
        id: sidebarPage

        PanelsPage { sectionKey: "sidebar" }
    }

    Component {
        id: overlayPage

        OverlayPage {}
    }

    Component {
        id: behaviourPage

        PanelsPage { sectionKey: "behaviour" }
    }

    // Device sections
    Component {
        id: audioPage

        AudioPage {}
    }

    Component {
        id: connectedDevicesPage

        ConnectedDevicesPage {}
    }

    // Power sections
    Component {
        id: idlePowerPage

        IdlePowerPage {}
    }

    Component {
        id: nightLightPage

        ServicesPage {
            sectionKey: "power"
            pageTitle: "Night light"
        }
    }

    // System sections
    Component {
        id: updatesPage

        UpdatesPage {}
    }

    Component {
        id: recordingPage

        ServicesPage {
            sectionKey: "recorder"
            pageTitle: "Screen recording"
        }
    }

    Component {
        id: pollingPage

        ServicesPage {
            sectionKey: "polling"
            pageTitle: "Background activity"
        }
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
