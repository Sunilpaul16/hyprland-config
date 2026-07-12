pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Per-monitor last-active-window tracking
Singleton {
    id: root


    property var byMonitor: ({})

    function record() {
        const tl = Hyprland.activeToplevel;

        if (!tl || !tl.monitor)
            return;
        const next = Object.assign({}, root.byMonitor);
        next[tl.monitor.name] = tl;
        root.byMonitor = next;
    }

    Component.onCompleted: root.record()

    // Update on active window change
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            root.record();
        }
    }

    function lastFor(monitor) {
        if (!monitor)
            return null;


        if (!Object.prototype.hasOwnProperty.call(root.byMonitor, monitor.name))
            return null;

        const recorded = root.byMonitor[monitor.name];
        const stillValid = recorded && Hyprland.toplevels.values.includes(recorded) && recorded.monitor === monitor;
        if (stillValid)
            return recorded;

        const ws = monitor.activeWorkspace;
        return ws ? (ws.toplevels.values[0] ?? null) : null;
    }
}
