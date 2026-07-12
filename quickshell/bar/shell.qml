import QtQuick
import Quickshell
import "launcher"
import "cheatsheet"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Launcher {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Cheatsheet {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        VolumeOsd {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        NotifPopups {
            property var modelData
            screen: modelData
        }
    }
}
