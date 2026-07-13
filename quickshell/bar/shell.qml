import QtQuick
import Quickshell
import "launcher"
import "cheatsheet"

ShellRoot {
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
}
