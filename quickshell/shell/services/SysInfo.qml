pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Distro identity, uptime
Singleton {
    id: root

    property string osId: ""
    property string osName: "Unknown OS"
    property real uptimeSeconds: 0

    // Static identity
    property string kernel: ""
    property string hostname: ""
    property string cpuModel: ""
    property real memoryTotalKib: 0

    readonly property string memoryTotalLabel: root.memoryTotalKib > 0 ? `${Math.round(root.memoryTotalKib / 1024 / 1024)} GiB` : ""

    // Distro glyphs
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

    // Short uptime
    readonly property string uptimeShort: {
        if (root.days > 0)
            return `${root.days}d ${root.hours}h`;
        if (root.hours > 0)
            return `${root.hours}h ${root.minutes}m`;
        return `${root.minutes}m`;
    }

    // Long uptime
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

    // Distro identity
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

    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }

    FileView {
        path: "/proc/cpuinfo"
        onLoaded: {
            const match = text().match(/^model name\s*:\s*(.+)$/m);
            if (match)
                root.cpuModel = match[1].replace(/\(R\)|\(TM\)|CPU |Processor /g, "").replace(/\s+/g, " ").trim();
        }
    }

    FileView {
        path: "/proc/meminfo"
        onLoaded: {
            const match = text().match(/^MemTotal:\s*(\d+)/m);
            if (match)
                root.memoryTotalKib = parseInt(match[1]);
        }
    }

    // Async reload
    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: {
            const seconds = parseFloat(text().split(" ")[0]);
            if (!isNaN(seconds))
                root.uptimeSeconds = seconds;
        }
    }

    // Uptime refresh
    Timer {
        interval: Config.polling.uptime
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }
}
