pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications


// Notification model
QtObject {
    id: notif


    // UI state
    property bool popup
    property bool closed
    property bool expanded

    property bool hovered

    property var locks: new Set()

    property date time: new Date()

    // Notification content (synced from Notification)
    property Notification notification
    property string notificationId
    property string summary
    property string body
    property string appIcon
    property string appName
    property string image
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: -1
    property list<var> actions

    readonly property bool critical: urgency === NotificationUrgency.Critical

    // Heuristic: **bold**, `code`, and [text](url) are distinctive enough
    // not to false-positive on plain text (unlike single */_ for italics,
    // which collide with things like "5 * 3")
    readonly property bool bodyHasMarkdown: /\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\)/.test(body)

    // Auto-dismiss timer
    readonly property Timer timer: Timer {
        // expireTimeout: 0 = never expire, -1 = server default, >0 = explicit ms
        running: notif.popup && !notif.closed && !notif.critical && !notif.hovered && notif.expireTimeout !== 0
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : Config.toastDismissDuration
        onTriggered: notif.popup = false
    }


    // Sync from Notification service
    readonly property Connections conn: Connections {
        target: notif.notification

        function onClosed(): void {
            notif.close();
        }
        function onSummaryChanged(): void { notif.summary = notif.notification.summary; }
        function onBodyChanged(): void { notif.body = notif.notification.body; }
        function onAppIconChanged(): void { notif.appIcon = notif.notification.appIcon; }
        function onAppNameChanged(): void { notif.appName = notif.notification.appName; }
        function onImageChanged(): void { notif.image = notif.notification.image; }
        function onUrgencyChanged(): void { notif.urgency = notif.notification.urgency; }
        function onActionsChanged(): void { notif.actions = notif.mapActions(); }
    }


    // Map DBus actions to plain objects
    function mapActions(): var {
        return notification.actions.map(a => ({
            identifier: a.identifier,
            text: a.text,
            invoke: () => a.invoke()
        }));
    }

    // Ref-counted lock & close (prevents destroy mid-animation)
    function lock(item: Item): void {
        locks.add(item);
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        closed = true;
        if (locks.size === 0 && Notifs.list.includes(this)) {
            Notifs.list = Notifs.list.filter(n => n !== this);
            notification?.dismiss();

            Qt.callLater(() => notif.destroy());
        }
    }

    // Initial snapshot from Notification
    Component.onCompleted: {
        if (!notification)
            return;
        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        appName = notification.appName;
        image = notification.image;
        urgency = notification.urgency;
        expireTimeout = notification.expireTimeout;
        actions = mapActions();
    }
}
