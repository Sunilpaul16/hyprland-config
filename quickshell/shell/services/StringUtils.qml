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
