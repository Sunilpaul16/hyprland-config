pragma Singleton
import QtQuick
import Quickshell

// Only one hover-driven panel open at a time — claiming the hover closes
// whichever panel held it (shared-coordinator shape, mirrors GlobalFocusGrab)
Singleton {
    id: root

    // The *State singleton currently owning the hover, or null
    property var current: null

    // current is set before closing the previous owner, so the release() that
    // fires from its own onOpenChanged doesn't clear the incoming claim
    function claim(owner): void {
        if (root.current === owner)
            return;
        const previous = root.current;
        root.current = owner;
        if (previous)
            previous.open = false;
    }

    function release(owner): void {
        if (root.current === owner)
            root.current = null;
    }
}
