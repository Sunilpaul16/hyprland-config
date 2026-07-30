pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
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
    property int notificationId: 0
    property string summary
    property string body
    property string appIcon
    property string appName
    property string image
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: -1
    property list<var> actions

    // "Show it, don't keep it" — volume/brightness/progress popups set this
    property bool isTransient

    readonly property bool critical: urgency === NotificationUrgency.Critical

    // Ticks off the shared clock rather than a timer per notification
    readonly property string timeStr: StringUtils.notifTime(time, Time.minutes)

    // Heuristic: **bold**, `code`, and [text](url) are distinctive enough
    // not to false-positive on plain text (unlike single */_ for italics,
    // which collide with things like "5 * 3")
    readonly property bool bodyHasMarkdown: /\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\)/.test(body)

    // Only the five tags the freedesktop spec defines, so a body merely
    // mentioning <something> doesn't get parsed as markup
    readonly property bool bodyHasMarkup: /<\/?(b|i|u|a|img)\b[^>]*>/i.test(body)

    // image-data arrives as an in-process provider URL, so it dies with the
    // shell — those have to be copied to disk to survive a restart
    readonly property bool imageIsVolatile: image.startsWith("image://qsimage/")

    function cacheKey(): string {
        const s = notif.appName + notif.summary + notif.notificationId + notif.image;
        let h1 = 0xdeadbeef, h2 = 0x41c6ce57;
        for (let i = 0; i < s.length; i++) {
            const ch = s.charCodeAt(i);
            h1 = Math.imul(h1 ^ ch, 2654435761);
            h2 = Math.imul(h2 ^ ch, 1597334677);
        }
        h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909);
        h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909);
        return ((h2 >>> 0).toString(16).padStart(8, "0") + (h1 >>> 0).toString(16).padStart(8, "0"));
    }

    function cacheImageIfVolatile(): void {
        if (notif.imageIsVolatile)
            grabLoader.active = true;
    }

    // Offscreen surface the grab needs — an Item only renders inside a window
    readonly property LazyLoader grabLoader: LazyLoader {
        id: grabLoader
        active: false

        PanelWindow {
            color: "transparent"
            implicitWidth: 64
            implicitHeight: 64
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-notif-imagecache"
            mask: Region {}

            Image {
                anchors.fill: parent
                source: notif.image
                fillMode: Image.PreserveAspectFit
                cache: false
                asynchronous: true

                onStatusChanged: {
                    if (status !== Image.Ready)
                        return;
                    const dest = `${Directories.notifImageCache}/${notif.cacheKey()}.png`;
                    grabToImage(result => {
                        if (result.saveToFile(dest))
                            notif.image = dest;
                        grabLoader.active = false;
                    });
                }
            }
        }
    }

    // Auto-dismiss timer
    readonly property Timer timer: Timer {
        // expireTimeout: 0 = never expire, -1 = server default, >0 = explicit ms
        running: notif.popup && !notif.closed && !notif.critical && !notif.hovered && notif.expireTimeout !== 0
        // A sender's explicit timeout wins; otherwise fullscreen gets the brief one
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : Notifs.anyFullscreen ? Config.notifications.fullscreenExpireDuration : Config.notifications.toastDismissDuration
        // A transient leaves entirely rather than falling back into history
        onTriggered: if (notif.isTransient) notif.close(); else notif.popup = false;
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
        function onImageChanged(): void { notif.image = notif.notification.image; notif.cacheImageIfVolatile(); }
        function onUrgencyChanged(): void { notif.urgency = notif.notification.urgency; }
        function onTransientChanged(): void { notif.isTransient = notif.notification.transient; }
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
        // Offset avoids colliding with history — Quickshell's own ids restart at 1 every run
        notificationId = notification.id + Notifs.idOffset;
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        appName = notification.appName;
        image = notification.image;
        urgency = notification.urgency;
        isTransient = notification.transient;
        expireTimeout = notification.expireTimeout;
        actions = mapActions();
        cacheImageIfVolatile();
    }
}
