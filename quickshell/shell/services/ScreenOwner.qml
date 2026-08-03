pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Monitor pinning
Singleton {
    id: root

    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""

    // Claim monitor
    function claim(state: var): void {
        state.ownerScreen = root.focusedName;
    }

    // Owns screen
    function owns(state: var, screen: var): bool {
        if (!screen)
            return false;
        const owner = state.ownerScreen;
        const live = owner !== "" && Quickshell.screens.some(s => s.name === owner);
        return screen.name === (live ? owner : root.focusedName);
    }

    // Toggle
    function toggle(state: var): void {
        if (state.open) {
            // Move, not close
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
