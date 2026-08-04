pragma Singleton

import QtQuick
import Quickshell

// Clock singleton
Singleton {
    id: root

    readonly property bool use12Hour: Config.time.use12Hour

    // Passthrough properties from SystemClock
    property alias enabled: clock.enabled
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    // Formatted strings
    // "h:mm AP" | "hh:mm"
    readonly property string clockFormat: root.use12Hour ? "h:mm AP" : "hh:mm"
    // Padded, so the bar does not jitter
    readonly property string timeStr: format(root.use12Hour ? "hh:mm AP" : "hh:mm")
    readonly property string hourStr: format("hh")
    readonly property string minuteStr: format("mm")
    readonly property string amPmStr: root.use12Hour ? format("AP") : ""

    readonly property string dateStr: format("ddd, MMM d")

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    // Underlying system clock
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
