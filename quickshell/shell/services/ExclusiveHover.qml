pragma Singleton
import QtQuick
import Quickshell

// Hover exclusivity
Singleton {
    id: root

    // Current owner
    property var current: null

    // Claim hover
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
