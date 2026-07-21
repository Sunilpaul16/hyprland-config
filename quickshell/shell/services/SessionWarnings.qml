pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Point-in-time checks for "is it safe to reboot/poweroff right now" —
// refreshed once when the session drawer opens, not polled continuously
// (comparison.md #31, ported from end-4)
Singleton {
    id: root

    property bool packageManagerRunning: false
    property bool downloadRunning: false

    function refresh(): void {
        root.packageManagerRunning = false;
        root.downloadRunning = false;
        detectPackageManagerProc.running = false;
        detectPackageManagerProc.running = true;
        detectDownloadProc.running = false;
        detectDownloadProc.running = true;
    }

    // Either a known package-manager frontend is running, or pacman's own
    // lock file is present (covers the frontend already having exited
    // while pacman itself is still mid-transaction)
    Process {
        id: detectPackageManagerProc
        command: ["bash", "-c", "pidof yay paru pacman dnf zypper apt apx xbps snap apk yum >/dev/null 2>&1 || ls /var/lib/pacman/db.lck >/dev/null 2>&1"]
        onExited: exitCode => {
            root.packageManagerRunning = (exitCode === 0);
        }
    }

    // Either a known downloader is running, or a partial-download file is
    // sitting in ~/Downloads (covers browser downloads, which never show
    // up as a curl/wget/etc. process)
    Process {
        id: detectDownloadProc
        command: ["bash", "-c", "pidof curl wget aria2c yt-dlp >/dev/null 2>&1 || ls ~/Downloads 2>/dev/null | grep -qE '\\.crdownload$|\\.part$'"]
        onExited: exitCode => {
            root.downloadRunning = (exitCode === 0);
        }
    }
}
