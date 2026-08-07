pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Shared focus grab
Singleton {
    id: root

    signal dismissed()

    property list<var> dismissable: []
    property list<var> persistent: []

    // Add dismissable
    function addDismissable(window): void {
        if (root.dismissable.indexOf(window) === -1)
            root.dismissable = [...root.dismissable, window];
    }

    function removeDismissable(window): void {
        root.dismissable = root.dismissable.filter(w => w !== window);
    }

    function addPersistent(window): void {
        if (root.persistent.indexOf(window) === -1)
            root.persistent = [...root.persistent, window];
    }

    function removePersistent(window): void {
        root.persistent = root.persistent.filter(w => w !== window);
    }

    // Windows deregister themselves
    function dismiss(): void {
        root.dismissed();
    }

    // Native hyprland_focus_grab_v1 grab
    HyprlandFocusGrab {
        windows: [...root.dismissable, ...root.persistent]
        active: root.dismissable.length > 0
        onCleared: root.dismiss()
    }
}
