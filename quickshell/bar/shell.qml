import QtQuick
import Quickshell
import "launcher"
import "cheatsheet"

// Entry point — this is what `qs -c bar` loads.
ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {
            property var modelData
            screen: modelData
        }
    }

    // Multi-mode launcher overlay (apps / ">" commands / wallpaper), one per
    // monitor (only the focused one ever shows itself — see Launcher.qml).
    // Opened via `qs -c bar ipc call launcher openApps` or `openWallpaper`.
    Variants {
        model: Quickshell.screens

        Launcher {
            property var modelData
            screen: modelData
        }
    }

    // Keybind cheatsheet overlay, one per monitor, same focused-only pattern
    // as the launcher above. Opened via `qs -c bar ipc call cheatsheet toggle`.
    Variants {
        model: Quickshell.screens

        Cheatsheet {
            property var modelData
            screen: modelData
        }
    }

    // Volume OSD, one per monitor, same focused-only pattern -- but purely
    // reactive to Audio.volume/Audio.muted, no IPC toggle to open it.
    Variants {
        model: Quickshell.screens

        VolumeOsd {
            property var modelData
            screen: modelData
        }
    }
}
