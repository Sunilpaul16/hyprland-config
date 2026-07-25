pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Distro identity + system uptime. Shared by the sidebar's system header and
// the dashboard's User card so neither re-reads /proc/uptime on its own.
Singleton {
    id: root

    property string osId: ""
    property string osName: "Unknown OS"
    property real uptimeSeconds: 0

    // Nerd Font distro glyphs, generic tux when the ID isn't mapped
    readonly property string osGlyph: {
        const map = {
            arch: "\uf303",
            endeavouros: "\uf322",
            manjaro: "\uf312",
            debian: "\uf306",
            ubuntu: "\uf31b",
            fedora: "\uf30a",
            nixos: "\uf313",
            gentoo: "\uf30d",
            opensuse: "\uf314"
        };
        return map[root.osId] ?? "\uf17c";
    }

    readonly property int days: Math.floor(root.uptimeSeconds / 86400)
    readonly property int hours: Math.floor((root.uptimeSeconds % 86400) / 3600)
    readonly property int minutes: Math.floor((root.uptimeSeconds % 3600) / 60)

    // Compact, for the sidebar header — "46m" / "2h 47m" / "3d 6h"
    readonly property string uptimeShort: {
        if (root.days > 0)
            return `${root.days}d ${root.hours}h`;
        if (root.hours > 0)
            return `${root.hours}h ${root.minutes}m`;
        return `${root.minutes}m`;
    }

    // Verbose, for the dashboard User card — "up 2 hours, 47 minutes"
    readonly property string uptimeLong: {
        let str = "";
        if (root.days > 0)
            str += `${root.days} day${root.days === 1 ? "" : "s"}`;
        if (root.hours > 0)
            str += `${str ? ", " : ""}${root.hours} hour${root.hours === 1 ? "" : "s"}`;
        if (root.minutes > 0 || !str)
            str += `${str ? ", " : ""}${root.minutes} minute${root.minutes === 1 ? "" : "s"}`;
        return "up " + str;
    }

    // Distro ID + pretty name — read once, not polled
    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const content = text();
            const id = content.match(/^ID=(.+)$/m);
            if (id)
                root.osId = id[1].replace(/"/g, "").trim().toLowerCase();
            const pretty = content.match(/^PRETTY_NAME=(.+)$/m);
            if (pretty)
                root.osName = pretty[1].replace(/"/g, "").trim();
        }
    }

    // reload() is async — text() must be read from onLoaded, not right after calling reload()
    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: {
            const seconds = parseFloat(text().split(" ")[0]);
            if (!isNaN(seconds))
                root.uptimeSeconds = seconds;
        }
    }

    // Uptime doesn't need to be precise — refresh once a minute, not every second
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }
}
