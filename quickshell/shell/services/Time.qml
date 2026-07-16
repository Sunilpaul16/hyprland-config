pragma Singleton

import QtQuick
import Quickshell

// Clock singleton
Singleton {
    id: root

    readonly property bool use12Hour: Config.use12Hour

    // Passthrough properties from SystemClock
    property alias enabled: clock.enabled
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    // Formatted strings
    readonly property string timeStr: format(root.use12Hour ? "hh:mm:A" : "hh:mm")
    readonly property list<string> timeComponents: timeStr.split(":")
    readonly property string hourStr: timeComponents[0] ?? ""
    readonly property string minuteStr: timeComponents[1] ?? ""
    readonly property string amPmStr: timeComponents[2] ?? ""

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
