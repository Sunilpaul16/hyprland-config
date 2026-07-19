pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Physical-disk usage: merges df's per-mount used/total with lsblk's
// partition -> parent-disk (PKNAME) mapping, so multiple mounts on one
// physical disk (this box's /, /boot, /home all on one nvme0n1) show as a
// single card instead of three.
Singleton {
    id: root

    property int refCount: 0

    function ref(): void {
        root.refCount++;
    }

    function unref(): void {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    // Each entry: { name, usedKib, totalKib, percentage, hasRoot }
    property var disks: []
    readonly property var primaryDisk: root.disks.length > 0 ? root.disks[0] : null

    property string _dfText: ""

    function flattenLsblk(node, map): void {
        map[node.name] = { pkname: node.pkname, mountpoint: node.mountpoint };
        if (node.children) {
            for (const child of node.children)
                root.flattenLsblk(child, map);
        }
    }

    function resolveDisk(name, map, depth): string {
        const entry = map[name];
        if (depth > 8 || !entry || !entry.pkname)
            return name;
        return root.resolveDisk(entry.pkname, map, depth + 1);
    }

    function parseStorage(dfText: string, lsblkText: string): void {
        if (!dfText || !lsblkText)
            return;

        let lsblkData;
        try {
            lsblkData = JSON.parse(lsblkText);
        } catch (e) {
            return;
        }

        const devMap = {};
        for (const dev of lsblkData.blockdevices)
            root.flattenLsblk(dev, devMap);

        const lines = dfText.trim().split("\n").slice(1);
        const byDisk = {};
        for (const line of lines) {
            const parts = line.trim().split(/\s+/);
            if (parts.length < 5)
                continue;

            const source = parts[0];
            const mount = parts[1];
            const usedKib = parseFloat(parts[3]);
            const totalKib = parseFloat(parts[4]);
            if (!source.startsWith("/dev/") || isNaN(usedKib) || isNaN(totalKib) || totalKib <= 0)
                continue;

            const devName = source.slice("/dev/".length);
            const diskName = root.resolveDisk(devName, devMap, 0);
            if (diskName.startsWith("zram"))
                continue;

            if (!byDisk[diskName])
                byDisk[diskName] = { name: diskName, usedKib: 0, totalKib: 0, hasRoot: false };
            byDisk[diskName].usedKib += usedKib;
            byDisk[diskName].totalKib += totalKib;
            if (mount === "/")
                byDisk[diskName].hasRoot = true;
        }

        const next = Object.values(byDisk).map(d => ({
            name: d.name,
            usedKib: d.usedKib,
            totalKib: d.totalKib,
            percentage: d.totalKib > 0 ? d.usedKib / d.totalKib : 0,
            hasRoot: d.hasRoot
        }));
        next.sort((a, b) => {
            if (a.hasRoot !== b.hasRoot)
                return a.hasRoot ? -1 : 1;
            return a.name < b.name ? -1 : 1;
        });

        root.disks = next;
    }

    Process {
        id: lsblkProc
        command: ["lsblk", "-J", "-b", "-o", "NAME,MOUNTPOINT,PKNAME"]
        stdout: StdioCollector { id: lsblkStdout }
        onExited: exitCode => {
            if (exitCode === 0)
                root.parseStorage(root._dfText, lsblkStdout.text);
        }
    }

    Process {
        id: dfProc
        command: ["df", "-k", "--output=source,target,fstype,used,size", "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs", "-x", "overlay", "-x", "efivarfs"]
        stdout: StdioCollector { id: dfStdout }
        onExited: exitCode => {
            if (exitCode === 0) {
                root._dfText = dfStdout.text;
                lsblkProc.running = true;
            }
        }
    }

    // Storage doesn't change fast — poll far less often than CPU/memory
    Timer {
        interval: 10000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: dfProc.running = true
    }
}
