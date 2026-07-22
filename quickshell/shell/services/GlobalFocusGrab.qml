pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Shared Hyprland focus grab spanning every currently-open overlay, replacing
// each panel's own full-screen click-catcher + independent Exclusive grab
// (comparison.md #47, ported from end-4's GlobalFocusGrab.qml)
Singleton {
    id: root

    signal dismissed()

    property list<var> dismissable: []
    property list<var> persistent: []

    // Reassign (not push/splice) so the list property's change notification
    // actually fires and the HyprlandFocusGrab binding below re-evaluates
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

    function dismiss(): void {
        root.dismissable = [];
        root.dismissed();
    }

    // Native hyprland_focus_grab_v1 grab
    HyprlandFocusGrab {
        windows: [...root.dismissable, ...root.persistent]
        active: root.dismissable.length > 0
        onCleared: root.dismiss()
    }
}
