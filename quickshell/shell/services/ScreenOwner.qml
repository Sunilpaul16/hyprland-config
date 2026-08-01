pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Pins an overlay to the monitor it opened on — panels ask owns(), keybinds use toggle(), which re-targets to the current monitor rather than closing
Singleton {
    id: root

    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""

    // Any deliberate open action claims the monitor the user is on
    function claim(state: var): void {
        state.ownerScreen = root.focusedName;
    }

    // Falls back to the focused monitor when the owner is unset or unplugged,
    // so a panel can't be stranded open on a screen that no longer exists
    function owns(state: var, screen: var): bool {
        if (!screen)
            return false;
        const owner = state.ownerScreen;
        const live = owner !== "" && Quickshell.screens.some(s => s.name === owner);
        return screen.name === (live ? owner : root.focusedName);
    }

    // closed -> open here; open on another monitor -> move here; open here -> close
    function toggle(state: var): void {
        if (state.open) {
            // Move rather than close when the keybind is pressed elsewhere
            if (state.ownerScreen !== root.focusedName) {
                state.ownerScreen = root.focusedName;
                return;
            }
            state.open = false;
            return;
        }
        root.claim(state);
        state.open = true;
    }
}
