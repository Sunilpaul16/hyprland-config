pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications


// Notification model
QtObject {
    id: notif


    property bool popup
    property bool closed
    property bool expanded

    property bool hovered

    property var locks: new Set()

    property date time: new Date()

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

    // Auto-dismiss timer — only hides the toast popup; the notification
    // itself stays in Notifs.list (history) until explicitly cleared
    readonly property Timer timer: Timer {
        running: notif.popup && !notif.closed && !notif.critical && !notif.hovered
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : 5000
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


    function mapActions(): var {
        return notification.actions.map(a => ({
            identifier: a.identifier,
            text: a.text,
            invoke: () => a.invoke()
        }));
    }

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
