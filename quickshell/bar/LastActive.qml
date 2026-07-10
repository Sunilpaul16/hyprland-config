pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Per-monitor "last active window" tracking -- works around a real gap in
// Quickshell's Hyprland data model: HyprlandToplevel's `.activated` mirrors
// wlr-foreign-toplevel-management's single global focus flag, not one
// tracked per output, and neither HyprlandMonitor nor HyprlandWorkspace
// expose a "last focused window on this output" pointer. Only
// Hyprland.activeToplevel (global) + that toplevel's own `.monitor` exist.
//
// So: every time the *global* active toplevel changes, record it under
// whichever monitor it's actually on. Purely event-driven off
// activeToplevelChanged -- no hyprctl, no polling.
Singleton {
    id: root

    // monitor name -> HyprlandToplevel. A plain object, reassigned (not
    // mutated in place) on every write so the property-change notify
    // actually fires -- mutating byMonitor[key] directly wouldn't.
    property var byMonitor: ({})

    function record() {
        const tl = Hyprland.activeToplevel;
        // No monitor to key off (no active toplevel at all, e.g. focus
        // landed on an empty workspace) -- leave prior recordings alone
        // rather than guessing which monitor "null" belongs to.
        if (!tl || !tl.monitor)
            return;
        const next = Object.assign({}, root.byMonitor);
        next[tl.monitor.name] = tl;
        root.byMonitor = next;
    }

    Component.onCompleted: root.record()

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            root.record();
        }
    }

    // Reads Hyprland.toplevels.values / recorded.monitor / the monitor's
    // activeWorkspace.toplevels as part of its own evaluation, so any
    // *caller* binding this into a property (e.g. ActiveWindow.qml's
    // `current`) automatically re-evaluates when a recorded window closes
    // or moves monitors -- no separate cleanup pass needed.
    function lastFor(monitor) {
        if (!monitor)
            return null;

        // Cold start: this monitor has never actually been focused since
        // the shell started, so there's nothing to fall back to either --
        // show nothing rather than guessing at a window that was never
        // really "last active" here.
        if (!Object.prototype.hasOwnProperty.call(root.byMonitor, monitor.name))
            return null;

        const recorded = root.byMonitor[monitor.name];
        const stillValid = recorded && Hyprland.toplevels.values.includes(recorded) && recorded.monitor === monitor;
        if (stillValid)
            return recorded;

        // Recorded window closed, or got moved to a different monitor --
        // evicted. Fall back to whatever's currently on this monitor's
        // active workspace, or nothing if it's genuinely empty.
        const ws = monitor.activeWorkspace;
        return ws ? (ws.toplevels.values[0] ?? null) : null;
    }
}
