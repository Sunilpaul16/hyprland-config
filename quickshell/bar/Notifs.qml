pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// D-Bus notification server (org.freedesktop.Notifications) plus the live list
// of notifications. Adapted from caelestia's services/Notifs.qml, stripped of
// its Config/Tokens/plugin deps.
//
// This is the popups-only chunk: no persistence, history panel, DND, grouping,
// or rate-limiting (each a later chunk). Every incoming notification is wrapped
// in a Notif (see Notif.qml) carrying UI state + the lock that keeps it alive
// while its card animates out.
//
// No startup-grace guard here, unlike the volume OSD: onNotification is a real
// D-Bus event, not a property that re-fires on async settle, and keepOnReload
// starts the server fresh — so there's nothing to replay on load to guard
// against. A grace window would only risk dropping a genuine notification fired
// right at login.
Singleton {
    id: root

    // All live notifications, newest first. popups is the reactive subset the
    // popup stack renders (NotifPopups.qml). Reassigned, never mutated in
    // place, so the list-changed notification actually fires.
    property list<Notif> list: []
    readonly property list<Notif> popups: list.filter(n => n.popup && !n.closed)

    // keepOnReload:false — notifications don't survive a shell reload this
    // chunk. When persistence lands (history chunk), persisted notifications
    // must have their actions cleared on load: action invocation calls back
    // into the live D-Bus sender, which no longer exists after a restart.
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

    // `qs -c bar ipc call notifs clear` dismisses everything on screen.
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
