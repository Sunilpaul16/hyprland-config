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

    // Notification content
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

    // Material icon fallback
    property string materialIcon

    // Transient flag
    property bool isTransient

    readonly property bool critical: urgency === NotificationUrgency.Critical

    // Shared clock
    readonly property string timeStr: StringUtils.notifTime(time, Time.minutes)

    // Markdown heuristic
    readonly property bool bodyHasMarkdown: /\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\)/.test(body)

    // Spec markup tags
    readonly property bool bodyHasMarkup: /<\/?(b|i|u|a|img)\b[^>]*>/i.test(body)

    // Volatile image URL
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

    // Offscreen grab surface
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
        // Timeout semantics
        running: notif.popup && !notif.closed && !notif.critical && !notif.hovered && notif.expireTimeout !== 0
        // Timeout precedence
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : Notifs.anyFullscreen ? Config.notifications.fullscreenExpireDuration : Config.notifications.toastDismissDuration
        // Transient closes
        onTriggered: if (notif.isTransient) notif.close(); else notif.popup = false;
    }


    // Sync from service
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


    // Map DBus actions
    function mapActions(): var {
        return notification.actions.map(a => ({
            identifier: a.identifier,
            text: a.text,
            invoke: () => a.invoke()
        }));
    }

    // Default or sole action
    function defaultAction(): var {
        return notif.actions.find(a => a.identifier === "default") ?? (notif.actions.length === 1 ? notif.actions[0] : null);
    }

    function activate(): bool {
        const action = notif.defaultAction();
        if (!action)
            return false;
        action.invoke();
        return true;
    }

    // Ref-counted lock
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

    // Initial snapshot
    Component.onCompleted: {
        if (!notification)
            return;
        // Id offset
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
