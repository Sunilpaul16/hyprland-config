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
                // the sidebar's Notifications card — still lands in history.
                popup: !SidebarRightState.open,
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
