pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tiny shared on/off switch for the cheatsheet overlay, same shape as
// launcher/LauncherState.qml — a singleton (not a per-window property)
// because the IPC call and the per-monitor Cheatsheet instances (one per
// screen, like Bar.qml/Launcher.qml) all need to see the same state.
Singleton {
    id: root

    property bool open: false

    // Re-run `hyprctl binds -j` each time the sheet opens (see
    // cheatsheet/Binds.qml) -- keybinds only change on a config reload, so
    // there's nothing to gain from parsing it while the sheet is closed.
    onOpenChanged: if (root.open) Binds.refresh()

    function toggle(): void {
        root.open = !root.open;
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }
    }
}
