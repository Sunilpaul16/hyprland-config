//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION = 10000

import QtQuick
import Quickshell
import "services"
import "modules/bar"
import "modules/dashboard"
import "modules/launcher"
import "modules/cheatsheet"
import "modules/mediaPopup"
import "modules/notifications"
import "modules/overview"
import "modules/session"
import "modules/sidebarRight"
import "modules/trayMenu"
import "modules/volumeOsd"

// Shell entrypoint
ShellRoot {
    // Force ColorsLoader's lazy singleton to load and apply matugen's
    // last-written theme (see ColorsLoader.qml)
    Component.onCompleted: ColorsLoader.reapplyTheme()

    // For each monitor: bar
    Variants {
        model: Quickshell.screens

        Bar {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: launcher
    Variants {
        model: Quickshell.screens

        Launcher {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: cheatsheet
    Variants {
        model: Quickshell.screens

        Cheatsheet {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: volume OSD
    Variants {
        model: Quickshell.screens

        VolumeOsd {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: notification popups
    Variants {
        model: Quickshell.screens

        NotifPopups {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: session/power screen
    Variants {
        model: Quickshell.screens

        SessionScreen {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: media popup
    Variants {
        model: Quickshell.screens

        MediaPopup {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: tray context-menu popup
    Variants {
        model: Quickshell.screens

        TrayMenu {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: right sidebar (Notifications/Keep Awake/Screen
    // Recorder/Quick Toggles — static shell)
    Variants {
        model: Quickshell.screens

        SidebarRightPanel {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: workspace overview with live window thumbnails
    Variants {
        model: Quickshell.screens

        Overview {
            property var modelData
            screen: modelData
        }
    }

    // For each monitor: dashboard overlay (tabbed — Dashboard/Media/Performance/Weather)
    Variants {
        model: Quickshell.screens

        DashboardPanel {
            property var modelData
            screen: modelData
        }
    }
}
