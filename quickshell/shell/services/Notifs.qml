pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
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

    // Notification server
    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true;
            const wrapper = notifComp.createObject(root, {
                // Don't pop up a toast for something already visible live in
                // the sidebar's Notifications card, or while Do Not Disturb
                // is on — still lands in history either way.
                popup: !SidebarRightState.open && !DndState.enabled,
                notification: notif
            });
            root.list = [wrapper, ...root.list];
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
}
