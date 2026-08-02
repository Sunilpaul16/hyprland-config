import QtQuick
import "../../services"
import "../../components"

// Settings panel content — nav pane on the left, page area on the right
Item {
    id: root

    property bool panelActive: false

    readonly property int pad: 18
    readonly property int navWidth: Math.min(Config.settings.navWidth, Math.round(width * 0.4))

    // What the panel needs to be tall enough to show the whole nav list
    readonly property int naturalHeight: navList.naturalHeight + root.pad * 2

    // Page registry, index-aligned with SettingsState.currentPageIdx — `category` drives the nav grouping, and entries without a `component` fall back to placeholderPage
    readonly property var pageModel: [
        // Appearance
        { label: "Wallpaper & style", icon: "palette", description: "Wallpaper, fonts, colours", category: "appearance", component: wallpaperStylePage },

        // Connectivity
        { label: "Network", icon: "lan", description: "Ethernet, VPN, usage", category: "connectivity", component: networkPage },
        { label: "Connected devices", icon: "devices_other", description: "Bluetooth, pairing", category: "connectivity", component: connectedDevicesPage },
        { label: "Audio", icon: "volume_up", description: "App volumes, sound devices", category: "connectivity", component: audioPage },

        // System
        { label: "Updates", icon: "update", description: "System updates", category: "system", component: updatesPage },

        // Shell
        { label: "Panels", icon: "dock_to_bottom", description: "Dashboard, taskbar, launcher, sidebar", category: "shell", component: panelsPage },
        { label: "Services", icon: "build", description: "Poll intervals, notifications", category: "shell", component: servicesPage },

        // About
        { label: "About", icon: "info", description: "System information, credits", category: "about", component: aboutPage }
    ]

    // Sub-page registry — keyed by SettingsState.subPage
    readonly property var subPageModel: ({
        "wallpapers": wallpapersSubPage,
        "schemes": schemesSubPage,
        "tray": traySubPage
    })

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

        // Index actually rendered. Lags SettingsState.currentPageIdx by
        // switchAnim's fade-out half, so the swap lands while nothing is visible
        property int shownIdx: 0
        // Slide direction for the incoming page: down when moving further down
        // the nav list, up when moving back up
        property real slideFrom: 0

        readonly property var page: root.pageModel[shownIdx] ?? root.pageModel[0]
        // Lags SettingsState.subPage the same way shownIdx lags currentPageIdx
        property string shownSubPage: ""
        readonly property var subComponent: root.subPageModel[pageArea.shownSubPage] ?? null

        Loader {
            id: pageLoader

            width: pageArea.width
            height: pageArea.height

            sourceComponent: pageArea.subComponent ?? pageArea.page.component ?? placeholderPage
        }

        // Sub-page open/close reuses the page-switch animation, sliding in from
        // the right going deeper and back the other way returning
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
                // Clamp on the singleton, not just here — the nav highlight reads currentPageIdx directly, so an out-of-range `ipc call settings page N` would select nothing
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
                duration: Motion.quickDuration
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
                duration: Motion.quickDuration
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
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        width: 30
        height: 30
        radius: width / 2
        color: closeHover.containsMouse ? Colors.layer : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            anchors.centerIn: parent
            text: "close"
            color: closeHover.containsMouse ? Colors.error : Colors.textMuted
            font.pixelSize: Motion.fontSize.header

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        MouseArea {
            id: closeHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SettingsState.open = false
        }
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

    // Pages
    Component {
        id: wallpaperStylePage

        WallpaperStylePage {}
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
        id: panelsPage

        PanelsPage {}
    }

    Component {
        id: servicesPage

        ServicesPage {}
    }

    Component {
        id: aboutPage

        AboutPage {}
    }

    // Fallback body for every page that has no `component` yet
    Component {
        id: placeholderPage

        PlaceholderPage {
            title: pageArea.page.label
        }
    }
}
