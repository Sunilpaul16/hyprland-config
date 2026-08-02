pragma Singleton
import QtQuick

// Hand-written, NOT matugen-generated — ColorsLoader mutates these at runtime from colors.json, so a theme change cross-fades instead of restarting the shell
// Values below are last-known-good defaults, used until the first reapplyTheme() completes
QtObject {
    id: root

    // Pulls a surface toward an accent — the shell's one way to derive a tonal fill, so amount stays explicit at the call site
    function tint(base: color, accent: color, amount: real): color {
        return Qt.tint(base, Qt.alpha(accent, amount));
    }

    // Rotates hue while holding saturation/lightness, for accents derived from primary; a greyscale input has no hue to turn
    function hueShift(c: color, degrees: real): color {
        if (c.hslSaturation <= 0.01)
            return c;
        return Qt.hsla((c.hslHue * 360 + degrees + 360) % 360 / 360, c.hslSaturation, c.hslLightness, c.a);
    }

    function luminance(c: color): real {
        return Math.sqrt(0.299 * c.r ** 2 + 0.587 * c.g ** 2 + 0.114 * c.b ** 2);
    }

    // Moves `c` away from `base` until it clears `target` luminance separation in whichever direction this palette elevates, then applies `alpha`
    function elevate(base: color, c: color, target: real, alpha: real): color {
        const lc = root.luminance(c);
        const delta = root.isLight ? root.luminance(base) - lc : lc - root.luminance(base);
        // Palette already separates them well enough; blending further would only flatten its own intent
        if (delta >= target)
            return Qt.alpha(c, alpha);
        const room = root.isLight ? lc : 1 - lc;
        if (room <= 0.001)
            return Qt.alpha(c, alpha);
        // Blending a fraction t toward black/white shifts luminance by roughly t * room
        const t = Math.min(1, (target - delta) / room);
        const toward = root.isLight ? 0 : 1;
        return Qt.rgba(c.r + (toward - c.r) * t, c.g + (toward - c.g) * t, c.b + (toward - c.b) * t, alpha);
    }

    // Light palettes elevate darker, dark palettes lighter. Derived from the palette because Theme.mode can be "auto", which never resolves to a concrete answer
    readonly property bool isLight: root.luminance(background) > 0.5

    // Floor on how far a raised surface must sit from the panel — 27 of the 29 presets already clear 0.043, so only the ones that don't get corrected
    readonly property real elevationFloor: 0.04

    // Outermost panel background — one role for every panel root and Corner fillet, or adjacent panels show the step as a hard line
    readonly property color panel: Config.appearance.transparency ? Qt.alpha(background, Config.appearance.panelOpacity) : background

    // Cards and pills on a panel — stacking two translucent layers always reads heavier, so the separation target grows with how see-through the panel is
    readonly property color layer: {
        const transparent = Config.appearance.transparency;
        const target = root.elevationFloor + (transparent ? 0.3 * (1 - Config.appearance.panelOpacity) : 0);
        return root.elevate(background, surface, target, transparent ? Config.appearance.layerOpacity : 1);
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

    // Text/icons sitting on a `primary` fill — same on<Capital> rename as text/textMuted below. Without it `background` stands in, which only reads while the palette is dark
    property color textOnPrimary: "#003546"
    Behavior on textOnPrimary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

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
