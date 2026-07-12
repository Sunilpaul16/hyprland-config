pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<Notif> list: []
    readonly property list<Notif> popups: list.filter(n => n.popup && !n.closed)

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
                popup: true,
                notification: notif
            });
            root.list = [wrapper, ...root.list];
        }
    }

    IpcHandler {
        target: "notifs"

        function clear(): void {
            for (const n of root.list.slice())
                n.close();
        }
    }

    Component {
        id: notifComp
        Notif {}
    }
}
