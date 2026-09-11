pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Time-of-day atmosphere for the wallpaper layer. This never rewrites themes.
Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool onBattery: battery?.isLaptopBattery
        && [UPowerDeviceState.Discharging, UPowerDeviceState.PendingDischarge].includes(battery.state)

    function minuteFromIso(value: string, fallback: int): int {
        if (!value)
            return fallback;
        const parsed = new Date(value);
        if (isNaN(parsed.getTime()))
            return fallback;
        return parsed.getHours() * 60 + parsed.getMinutes();
    }

    readonly property int sunriseMinute: Config.ambient.useSunTimes
        ? root.minuteFromIso(Weather.sunriseIso, 7 * 60) : 7 * 60
    readonly property int sunsetMinute: Config.ambient.useSunTimes
        ? root.minuteFromIso(Weather.sunsetIso, 19 * 60) : 19 * 60

    readonly property int nowMinute: Time.hours * 60 + Time.minutes
    readonly property int dawnStart: Math.max(0, root.sunriseMinute - 75)
    readonly property int dayStart: Math.min(1439, root.sunriseMinute + 75)
    readonly property int duskStart: Math.max(root.dayStart + 1, root.sunsetMinute - 90)
    readonly property int nightStart: Math.min(1439, root.sunsetMinute + 90)

    function smooth(value: real): real {
        const t = Math.max(0, Math.min(1, value));
        return t * t * (3 - 2 * t);
    }

    function mix(first: color, second: color, amount: real): color {
        return Colors.tint(first, second, root.smooth(amount));
    }

    function stop(name: string, top: color, bottom: color, opacity: real): var {
        return { name, top, bottom, opacity };
    }

    function blendStops(first: var, second: var, amount: real, name: string): var {
        const t = root.smooth(amount);
        return {
            name,
            top: root.mix(first.top, second.top, t),
            bottom: root.mix(first.bottom, second.bottom, t),
            opacity: first.opacity + (second.opacity - first.opacity) * t
        };
    }

    readonly property var nightStop: root.stop("Night", "#101936", "#29486b", 0.25)
    readonly property var dawnStop: root.stop("Dawn", "#72445f", "#ef936b", 0.19)
    readonly property var dayStop: root.stop("Day", "#86afc3", "#efd6ad", 0.035)
    readonly property var duskStop: root.stop("Dusk", "#684462", "#e56f52", 0.22)

    function automaticSample(minute: int): var {
        if (minute < root.dawnStart)
            return root.nightStop;
        if (minute < root.sunriseMinute)
            return root.blendStops(root.nightStop, root.dawnStop,
                (minute - root.dawnStart) / Math.max(1, root.sunriseMinute - root.dawnStart), "Dawn");
        if (minute < root.dayStart)
            return root.blendStops(root.dawnStop, root.dayStop,
                (minute - root.sunriseMinute) / Math.max(1, root.dayStart - root.sunriseMinute), "Dawn");
        if (minute < root.duskStart)
            return root.dayStop;
        if (minute < root.sunsetMinute)
            return root.blendStops(root.dayStop, root.duskStop,
                (minute - root.duskStart) / Math.max(1, root.sunsetMinute - root.duskStart), "Dusk");
        if (minute < root.nightStart)
            return root.blendStops(root.duskStop, root.nightStop,
                (minute - root.sunsetMinute) / Math.max(1, root.nightStart - root.sunsetMinute), "Dusk");
        return root.nightStop;
    }

    readonly property var phaseSample: {
        if (Config.ambient.mode === "dawn")
            return root.dawnStop;
        if (Config.ambient.mode === "day")
            return root.dayStop;
        if (Config.ambient.mode === "dusk")
            return root.duskStop;
        if (Config.ambient.mode === "night")
            return root.nightStop;
        return root.automaticSample(root.nowMinute);
    }

    function weatherColor(code: int): color {
        if ([95, 96, 99].includes(code))
            return "#59466f";
        if ([71, 73, 75, 77, 85, 86].includes(code))
            return "#b8d2df";
        if ([45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].includes(code))
            return "#526c7d";
        if (code === 0)
            return root.phaseSample.name === "Day" ? "#e1a25e" : "#314a72";
        return "transparent";
    }

    readonly property color weatherTint: root.weatherColor(Weather.weatherCode)
    readonly property bool hasWeatherTint: Config.ambient.weatherReactive
        && Weather.weatherCode >= 0 && root.weatherTint.a > 0

    readonly property color topTint: {
        let value = root.phaseSample.top;
        if (root.hasWeatherTint)
            value = root.mix(value, root.weatherTint, 0.22);
        if (FocusMode.enabled)
            value = root.mix(value, "#364c68", 0.28);
        return value;
    }

    readonly property color bottomTint: {
        let value = root.phaseSample.bottom;
        if (root.hasWeatherTint)
            value = root.mix(value, root.weatherTint, 0.28);
        if (FocusMode.enabled)
            value = root.mix(value, "#46627b", 0.24);
        return value;
    }

    readonly property real priorityMultiplier: (FocusMode.enabled ? 0.8 : 1)
        * (Config.ambient.reduceOnBattery && root.onBattery ? 0.65 : 1)
    readonly property bool suppressed: GameModeState.enabled
    readonly property real opacity: Config.ambient.enabled && !root.suppressed
        ? Math.max(0, Math.min(1, root.phaseSample.opacity * Config.ambient.intensity * root.priorityMultiplier
            + (root.hasWeatherTint ? 0.015 : 0))) : 0

    readonly property string phaseLabel: root.phaseSample.name
    readonly property string statusLabel: !Config.ambient.enabled ? "Off"
        : root.suppressed ? "Paused by game mode"
        : FocusMode.enabled ? `${root.phaseLabel} · calm focus`
        : (Config.ambient.reduceOnBattery && root.onBattery) ? `${root.phaseLabel} · reduced on battery`
        : root.phaseLabel

    function toggle(): void {
        Config.ambient.enabled = !Config.ambient.enabled;
        Notifs.toast(Config.ambient.enabled ? "Ambient mode on" : "Ambient mode off",
            Config.ambient.enabled ? `${root.phaseLabel} atmosphere is active` : "Wallpaper tint removed",
            Config.ambient.enabled ? "landscape" : "hide_image");
    }

    IpcHandler {
        target: "ambient"
        function toggle(): void { root.toggle(); }
        function enable(): void { Config.ambient.enabled = true; }
        function disable(): void { Config.ambient.enabled = false; }
        function automatic(): void { Config.ambient.mode = "auto"; }
        function dawn(): void { Config.ambient.mode = "dawn"; }
        function day(): void { Config.ambient.mode = "day"; }
        function dusk(): void { Config.ambient.mode = "dusk"; }
        function night(): void { Config.ambient.mode = "night"; }
        function status(): string {
            return `enabled=${Config.ambient.enabled} mode=${Config.ambient.mode} phase=${root.phaseLabel} opacity=${root.opacity.toFixed(3)} status=${root.statusLabel}`;
        }
    }
}
