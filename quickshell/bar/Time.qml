pragma Singleton

import QtQuick
import Quickshell

// Ported from caelestia-shell's services/Time.qml. Same shape (SystemClock-
// driven reactive properties, no polling), minus everything that came from
// the Caelestia plugin: `enabled`/`date`/`hours`/`minutes`/`seconds` below
// are genuine Quickshell.SystemClock properties (confirmed in
// quickshell-core.qmltypes), not plugin-supplied, so they carry over as-is.
// `use12Hour` replaces upstream's `GlobalConfig.services.useTwelveHourClock`
// — a plain property instead of a config-file-backed one, since this config
// has no Config/Tokens system to read from.
Singleton {
    id: root

    property bool use12Hour: false

    property alias enabled: clock.enabled
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    readonly property string timeStr: format(root.use12Hour ? "hh:mm:A" : "hh:mm")
    readonly property list<string> timeComponents: timeStr.split(":")
    readonly property string hourStr: timeComponents[0] ?? ""
    readonly property string minuteStr: timeComponents[1] ?? ""
    readonly property string amPmStr: timeComponents[2] ?? ""

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
