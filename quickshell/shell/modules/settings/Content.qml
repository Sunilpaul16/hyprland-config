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
        { label: "Wallpaper & style", icon: "palette", description: "Wallpaper, fonts, colours", category: "appearance", component: wallpaperStylePage },

        // Connectivity
        { label: "Network", icon: "lan", description: "Ethernet, VPN, usage", category: "connectivity", component: networkPage },
        { label: "Connected devices", icon: "devices_other", description: "Bluetooth, pairing", category: "connectivity", component: connectedDevicesPage },
        { label: "Audio", icon: "volume_up", description: "App volumes, sound devices", category: "connectivity", component: audioPage },

        // System
        { label: "Updates", icon: "update", description: "System updates", category: "system", component: updatesPage },
        { label: "Idle & power", icon: "bedtime", description: "Lock, displays, suspend", category: "system", component: idlePowerPage },

        // Shell
        { label: "Panels", icon: "dock_to_bottom", description: "Dashboard, taskbar, launcher, sidebar", category: "shell", component: panelsPage },
        { label: "Overlay widgets", icon: "widgets", description: "Crosshair, notes, floating image", category: "shell", component: overlayPage },
        { label: "Services", icon: "build", description: "Poll intervals, notifications", category: "shell", component: servicesPage },

        // About
        { label: "About", icon: "info", description: "System information, credits", category: "about", component: aboutPage }
    ]

    // Sub-page registry
    readonly property var subPageModel: ({
        "wallpapers": wallpapersSubPage,
        "schemes": schemesSubPage,
        "tray": traySubPage,
        "quickToggles": quickTogglesSubPage
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
