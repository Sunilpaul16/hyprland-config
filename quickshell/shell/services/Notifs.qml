pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Notification list singleton
Singleton {
    id: root

    property list<Notif> list: []
    readonly property list<Notif> popups: list.filter(n => n.popup && !n.closed)

    // Newest-notification timestamp per app, independent of list iteration order
    property var latestTimeForApp: ({})

    onListChanged: {
        for (const n of root.list) {
            if (!n.closed && (!root.latestTimeForApp[n.appName] || n.time > root.latestTimeForApp[n.appName]))
                root.latestTimeForApp[n.appName] = n.time;
        }
        for (const appName of Object.keys(root.latestTimeForApp)) {
            if (!root.list.some(n => n.appName === appName && !n.closed))
                delete root.latestTimeForApp[appName];
        }
        root.expandedApps = root.expandedApps.filter(appName => root.list.some(n => n.appName === appName && !n.closed));
        writeTimer.restart();
    }

    // Per-app groups (comparison.md #26)
    readonly property var groupsByAppName: {
        const groups = {};
        for (const n of root.list) {
            if (n.closed)
                continue;
            if (!groups[n.appName])
                groups[n.appName] = { appName: n.appName, notifs: [] };
            groups[n.appName].notifs.push(n);
        }
        for (const g of Object.values(groups)) {
            g.image = g.notifs.find(n => n.image.length > 0)?.image ?? "";
            g.appIcon = g.notifs.find(n => n.appIcon.length > 0)?.appIcon ?? "";
            g.urgency = g.notifs.some(n => n.urgency === NotificationUrgency.Critical) ? NotificationUrgency.Critical : (g.notifs.some(n => n.urgency === NotificationUrgency.Normal) ? NotificationUrgency.Normal : NotificationUrgency.Low);
            g.time = root.latestTimeForApp[g.appName] ?? g.notifs[0].time;
        }
        return groups;
    }

    readonly property var appNameList: Object.keys(root.groupsByAppName).sort((a, b) => root.groupsByAppName[b].time - root.groupsByAppName[a].time)

    // Expanded app groups — survives the group card being destroyed/recreated on re-layout
    property list<string> expandedApps: []

    function toggleAppExpand(appName: string): void {
        const idx = root.expandedApps.indexOf(appName);
        if (idx === -1)
            root.expandedApps = [...root.expandedApps, appName];
        else
            root.expandedApps = root.expandedApps.filter(a => a !== appName);
    }

    function clearAll(): void {
        for (const n of root.list.slice())
            n.close();
    }

    // A fullscreen window on the focused monitor — the special workspace wins
    // when one is open, since that's what's actually on screen
    readonly property bool anyFullscreen: {
        const monitor = Hyprland.focusedMonitor;
        const specialName = monitor?.lastIpcObject.specialWorkspace?.name ?? "";
        if (specialName.length > 0)
            return Hyprland.workspaces.values.find(ws => ws.name === specialName)?.hasFullscreen ?? false;
        return monitor?.activeWorkspace?.hasFullscreen ?? false;
    }

    // Counts only what actually toasted — something suppressed by DND or an
    // open sidebar was never unseen
    property int unread: 0

    function markAllRead(): void {
        root.unread = 0;
    }

    // Opening the sidebar is reading them
    Connections {
        target: SidebarRightState

        function onOpenChanged(): void {
            if (SidebarRightState.open)
                root.markAllRead();
        }
    }

    // idOffset keeps a fresh session's ids from colliding with history — applied in Notif.qml (comparison.md #27)
    property int idOffset: 0

    function notifToJSON(n) {
        return {
            notificationId: n.notificationId,
            appIcon: n.appIcon,
            appName: n.appName,
            body: n.body,
            image: n.image,
            summary: n.summary,
            time: n.time.getTime(),
            urgency: n.urgency
        };
    }

    function persist(): void {
        // Disabled means the file is actively emptied, not just left unwritten,
        // so turning it off doesn't leave an old history to restore later
        if (!Config.notifications.keepAcrossRestarts) {
            historyFile.setText("[]");
            return;
        }
        historyFile.setText(JSON.stringify(root.list.filter(n => !n.closed && !n.isTransient).map(n => root.notifToJSON(n)), null, 2));
    }

    // Notification server
    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        // Don't claim persistence to senders when history is turned off
        persistenceSupported: Config.notifications.keepAcrossRestarts

        onNotification: notif => {
            notif.tracked = true;
            const wrapper = notifComp.createObject(root, {
                // No toast when the sidebar card already shows it live, under Do Not Disturb, or over a fullscreen window if disabled — history gets it either way
                popup: !SidebarRightState.open && !DndState.enabled && !(Config.notifications.fullscreen === "off" && root.anyFullscreen),
                notification: notif
            });
            root.list = [wrapper, ...root.list];

            if (wrapper.popup && !wrapper.isTransient)
                root.unread++;

            // No popup means no dismiss timer, so a transient would never expire
            if (wrapper.isTransient && !wrapper.popup)
                wrapper.close();
        }
    }

    // IPC handler
    IpcHandler {
        target: "notifs"

        function clear(): void {
            root.clearAll();
        }
    }

    // Notif component factory
    Component {
        id: notifComp
        Notif {}
    }

    // Creates the image cache, then drops any file the restored history no
    // longer references — nothing else prunes it, so it would grow forever
    Process {
        id: cachePrune
        running: true
        command: ["bash", "-c", `mkdir -p '${Directories.notifImageCache}' && find '${Directories.notifImageCache}' -type f -printf '%f\\n' 2>/dev/null | while read -r f; do grep -qF "$f" '${Directories.notificationsFile}' 2>/dev/null || rm -f '${Directories.notifImageCache}'/"$f"; done`]
    }

    // Debounced write — avoids hammering disk on a burst of rapid notifications
    Timer {
        id: writeTimer
        interval: 200
        repeat: false
        onTriggered: root.persist()
    }

    // History file — reloaded notifs get actions: [], meaningless once the sender is dead (comparison.md #27)
    FileView {
        id: historyFile
        path: Directories.notificationsFile

        onLoaded: {
            if (!Config.notifications.keepAcrossRestarts) {
                root.list = [];
                return;
            }

            let parsed = [];
            try {
                parsed = JSON.parse(historyFile.text() || "[]");
            } catch (e) {
                parsed = [];
            }

            let maxId = 0;
            const restored = parsed.map(n => {
                maxId = Math.max(maxId, n.notificationId ?? 0);
                return notifComp.createObject(root, {
                    notificationId: n.notificationId ?? 0,
                    appIcon: n.appIcon ?? "",
                    appName: n.appName ?? "",
                    body: n.body ?? "",
                    image: n.image ?? "",
                    summary: n.summary ?? "",
                    time: new Date(n.time ?? 0),
                    urgency: n.urgency ?? NotificationUrgency.Normal
                });
            });

            root.idOffset = maxId;
            root.list = restored;
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                historyFile.setText("[]");
        }
    }
}
