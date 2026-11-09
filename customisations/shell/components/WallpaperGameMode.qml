import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var gameMode
    property bool initialized: false

    function sync(): void {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/caelestia/animated-wallpaper.py", "game-sync"]);
    }

    // Restore the session flag before scheduling playback or changing Hyprland.
    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/caelestia-wallpaper-game-mode"
        printErrors: false
        onLoaded: {
            root.gameMode.enabled = true;
            root.initialized = true;
            root.gameMode.setDynamicConfs();
            root.sync();
        }
        onLoadFailed: {
            root.initialized = true;
            root.sync();
        }
    }
}
