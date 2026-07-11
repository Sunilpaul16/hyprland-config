pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications

// One wrapped notification: mirrors the live Notification's fields into plain
// properties, owns the auto-dismiss timer, and implements the lock mechanism.
// Adapted from caelestia's services/NotifData.qml, minus persistence, image
// caching, and the fullscreen/DND logic (later chunks).
//
// The lock is the critical anti-crash piece. A card calls lock(this) when it
// appears and unlock(this) when it's destroyed. close() marks the notif closed
// but only actually dismisses + destroys once no locks remain — so the
// underlying Notification is never torn out from under a card still animating
// out (a dangling reference there crashes the shell). See NotifCard.qml.
QtObject {
    id: notif

    // popup: currently eligible to show as a popup. closed: dismissed, pending
    // teardown once the last card unlocks. expanded: reserved for the later
    // expand/collapse chunk (popups ship collapsed-only for now).
    property bool popup
    property bool closed
    property bool expanded
    // Set by the card while the pointer is over it, so the auto-dismiss timer
    // pauses on hover (gives the user time to read / click an action).
    property bool hovered

    // Cards currently keeping this notif alive. Mutated in place (add/delete)
    // on purpose — nothing binds to it reactively, it's only read imperatively
    // in close(), so the reassign-don't-mutate rule doesn't apply here.
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

    // Auto-dismiss the popup after a timeout. Critical notifications never
    // auto-dismiss (caelestia-style) — they stay until the user acts. Others
    // honor the app's expireTimeout when positive, else a 5s default. Going
    // through close() (not just hiding) is right for this popups-only chunk:
    // with no history there's nothing to keep a dismissed notif around for.
    // The history chunk will instead set popup=false here and keep the notif.
    readonly property Timer timer: Timer {
        running: notif.popup && !notif.closed && !notif.critical && !notif.hovered
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : 5000
        onTriggered: notif.close()
    }

    // Mirror live field changes, and close if the sending app closes it.
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

    // Flatten the live NotificationAction list into plain objects. Each keeps a
    // closure over the live action so invoke() reaches the real D-Bus sender —
    // which is exactly why persisted notifications (later) must drop actions.
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
            // Defer the actual object teardown to the next tick. close() reaches
            // here from a card's Component.onDestruction (via unlock), so the
            // card is still mid-teardown with live bindings onto this notif;
            // destroying synchronously nulls their modelData and throws a burst
            // of "TypeError: … of null". One tick later the card is fully gone.
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
