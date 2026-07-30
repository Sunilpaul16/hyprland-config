pragma Singleton
import QtQuick

// String helpers shared across services that shell out or format durations
QtObject {
    // Escapes a string for safe interpolation inside single-quoted bash —
    // closes the quote, escapes a literal quote, reopens it
    function shellSingleQuoteEscape(str: string): string {
        return String(str).replace(/'/g, "'\\''");
    }

    // Quickshell mangles an image-path hint into a broken icon-name-lookup URL — recover the real path
    function resolveNotifImage(image: string): string {
        const prefix = "image://icon/";
        if (image.startsWith(prefix) && image.slice(prefix.length).startsWith("/"))
            return Qt.resolvedUrl(image.slice(prefix.length));
        return Qt.resolvedUrl(image);
    }

    // Notification timestamp: relative under an hour, absolute after.
    // `tick` is unused — it's the binding dependency that reruns this each minute
    function notifTime(time: date, tick: int): string {
        const then = time.getTime();
        if (isNaN(then))
            return "";

        const clock = Config.time.use12Hour ? "h:mm AP" : "hh:mm";
        const mins = Math.floor((Date.now() - then) / 60000);

        if (mins < 1)
            return "now";
        if (mins < 60)
            return `${mins}m`;

        // Calendar days apart, not elapsed hours — 00:30 is "yesterday" at 01:00
        const startOfDay = d => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
        const days = Math.round((startOfDay(new Date()) - startOfDay(time)) / 86400000);

        if (days < 1)
            return Qt.formatDateTime(time, clock);
        // Capped at 6: at 7 the weekday matches today's and reads as this morning
        if (days < 7)
            return Qt.formatDateTime(time, `ddd ${clock}`);
        return Qt.formatDateTime(time, "MMM d");
    }

    // Formats seconds as m:ss, or h:mm:ss once an hour is crossed
    function friendlyTimeForSeconds(seconds: real): string {
        if (isNaN(seconds) || seconds < 0)
            return "0:00";
        seconds = Math.floor(seconds);
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        if (h > 0)
            return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
        return `${m}:${s.toString().padStart(2, '0')}`;
    }
}
