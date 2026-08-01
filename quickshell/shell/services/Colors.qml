pragma Singleton
import QtQuick

// Hand-written, NOT matugen-generated — ColorsLoader mutates these at runtime from colors.json, so a theme change cross-fades instead of restarting the shell
// Values below are last-known-good defaults, used until the first reapplyTheme() completes
QtObject {
    // Outermost panel background — one role for every panel root and Corner fillet, or adjacent panels show the step as a hard line
    readonly property color panel: Config.appearance.transparency ? Qt.alpha(background, Config.appearance.panelOpacity) : background

    // Cards and pills on a panel — stacking two translucent layers always reads heavier, so lift the tint (scaled by luminance, sized by panel transparency) to read as raised instead
    readonly property color layer: {
        if (!Config.appearance.transparency)
            return surface;
        const lift = 0.3 * (1 - Config.appearance.panelOpacity);
        const lum = Math.sqrt(0.299 * surface.r ** 2 + 0.587 * surface.g ** 2 + 0.114 * surface.b ** 2);
        const scale = lum > 0 ? (lum + lift) / lum : 1;
        return Qt.rgba(Math.min(1, surface.r * scale), Math.min(1, surface.g * scale), Math.min(1, surface.b * scale), Config.appearance.layerOpacity);
    }

    property color background: "#0f1417"
    Behavior on background { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color surface: "#1b2023"
    Behavior on surface { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color primary: "#8ad0ef"
    Behavior on primary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Accent roles for surfaces that need to distinguish several series at
    // once (the Performance tab gives CPU/GPU/Memory/Storage one each)
    property color secondary: "#b4c9d7"
    Behavior on secondary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color tertiary: "#c8c0e8"
    Behavior on tertiary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Tonal fill sitting a step above `surface` — progress-track backgrounds
    property color secondaryContainer: "#37474f"
    Behavior on secondaryContainer { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Named `text`/`textMuted`, not `onSurface`/`onSurfaceVariant` — QML
    // reserves "on<Capital>" property names for signal handlers.
    property color text: "#dfe3e6"
    Behavior on text { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color textMuted: "#c0c8cd"
    Behavior on textMuted { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color outline: "#8a9297"
    Behavior on outline { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Dimmer than `outline` — for dividers and hairlines, not focusable edges
    property color outlineVariant: "#3f484c"
    Behavior on outlineVariant { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Error / destructive roles — same on<Capital> rename as text/textMuted above, so the foregrounds become textOnError/textOnErrorContainer
    property color error: "#ffb4ab"
    Behavior on error { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color textOnError: "#690005"
    Behavior on textOnError { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color errorContainer: "#93000a"
    Behavior on errorContainer { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color textOnErrorContainer: "#ffdad6"
    Behavior on textOnErrorContainer { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Recording red — deliberately fixed, not a theme role: a recording indicator has to stay red whatever the palette does
    readonly property color recording: "#e64553"
}
