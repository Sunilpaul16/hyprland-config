pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reboot safety checks
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

    // Package manager busy
    Process {
        id: detectPackageManagerProc
        command: ["bash", "-c", "pidof yay paru pacman dnf zypper apt apx xbps snap apk yum >/dev/null 2>&1 || ls /var/lib/pacman/db.lck >/dev/null 2>&1"]
        onExited: exitCode => {
            root.packageManagerRunning = (exitCode === 0);
        }
    }

    // Downloads in flight
    Process {
        id: detectDownloadProc
        command: ["bash", "-c", "pidof curl wget aria2c yt-dlp >/dev/null 2>&1 || ls ~/Downloads 2>/dev/null | grep -qE '\\.crdownload$|\\.part$'"]
        onExited: exitCode => {
            root.downloadRunning = (exitCode === 0);
        }
    }
}
