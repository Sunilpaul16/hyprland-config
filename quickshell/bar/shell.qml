import QtQuick
import Quickshell
import "launcher"
import "cheatsheet"

// Entry point — this is what `qs -c bar` loads.
//
// Quickshell.screens is a plain list of the compositor's outputs (DP-3,
// DP-2 here). Variants instantiates one delegate per model item and keeps
// it in sync if outputs are added/removed; `modelData` is the item itself
// (a Qt Screen) for each delegate.
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
}
