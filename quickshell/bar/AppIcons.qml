pragma Singleton
import QtQuick
import Quickshell

// WM-class -> app-icon resolution, shared by Workspaces.qml (per-workspace
// app icons) and ActiveWindow.qml (focused-window icon) -- pulled out into
// its own singleton so the second consumer doesn't duplicate the matching
// logic Workspaces.qml already had.
Singleton {
    id: root

    // Real DesktopEntry list, for mapping a window's WM class to an app
    // icon. A genuine property binding (not a one-off snapshot read) --
    // DesktopEntries populates asynchronously over the first second or so
    // after the shell starts, and only a real binding reliably tracks that
    // as entries arrive (confirmed empirically with a throwaway qs -p
    // script when this lived directly in Workspaces.qml).
    readonly property var desktopEntries: DesktopEntries.applications.values

    // Best-effort WM-class -> desktop-entry-icon match. Not a fuzzy
    // matcher -- just the two fields desktop files actually use for this
    // (StartupWMClass, and the common convention that a .desktop file's
    // own id matches its app's WM class), case-insensitively. Empty string
    // means "no match".
    function resolve(wmClass) {
        if (!wmClass)
            return "";
        const lower = wmClass.toLowerCase();
        const entry = root.desktopEntries.find(e => (e.startupClass && e.startupClass.toLowerCase() === lower) || e.id.toLowerCase() === lower || e.id.toLowerCase() === `${lower}.desktop`);
        return entry ? entry.icon : "";
    }
}
