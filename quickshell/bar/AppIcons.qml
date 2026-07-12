pragma Singleton
import QtQuick
import Quickshell


Singleton {
    id: root
    readonly property var desktopEntries: DesktopEntries.applications.values
    function resolve(wmClass) {
        if (!wmClass)
            return "";
        const lower = wmClass.toLowerCase();
        const entry = root.desktopEntries.find(e => (e.startupClass && e.startupClass.toLowerCase() === lower) || e.id.toLowerCase() === lower || e.id.toLowerCase() === `${lower}.desktop`);
        return entry ? entry.icon : "";
    }
}
