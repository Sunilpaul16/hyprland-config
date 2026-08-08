pragma Singleton
import QtQuick

// Theme colour roles
QtObject {
    id: root

    // Tint toward accent
    function tint(base: color, accent: color, amount: real): color {
        return Qt.tint(base, Qt.alpha(accent, amount));
    }

    // Rotate hue
    function hueShift(c: color, degrees: real): color {
        // Greys need a hue to rotate
        const sat = Math.max(c.hslSaturation, 0.25);
        return Qt.hsla((c.hslHue * 360 + degrees + 360) % 360 / 360, sat, c.hslLightness, c.a);
    }

    // Straight RGB distance
    function distance(a: color, b: color): real {
        return Math.sqrt((a.r - b.r) ** 2 + (a.g - b.g) ** 2 + (a.b - b.b) ** 2);
    }

    function luminance(c: color): real {
        return Math.sqrt(0.299 * c.r ** 2 + 0.587 * c.g ** 2 + 0.114 * c.b ** 2);
    }

    // WCAG relative luminance
    function relLuminance(c: color): real {
        const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
    }

    // WCAG contrast ratio
    function contrast(a: color, b: color): real {
        const la = root.relLuminance(a);
        const lb = root.relLuminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // Minimum text contrast
    readonly property real contrastFloor: 4.5

    // Accent legible on panel
    function readable(c: color): color {
        if (root.contrast(c, root.background) >= root.contrastFloor)
            return c;
        // Lift lightness, keep hue
        const shade = l => Qt.hsla(c.hslHue, c.hslSaturation, l, c.a);
        let lo = c.hslLightness;
        let hi = root.isLight ? 0 : 1;
        for (let i = 0; i < 14; i++) {
            const m = (lo + hi) / 2;
            if (root.contrast(shade(m), root.background) >= root.contrastFloor)
                hi = m;
            else
                lo = m;
        }
        return shade(hi);
    }

    // Elevate above base
    function elevate(base: color, c: color, target: real, alpha: real): color {
        const lc = root.luminance(c);
        const delta = root.isLight ? root.luminance(base) - lc : lc - root.luminance(base);
        // Already separated
        if (delta >= target)
            return Qt.alpha(c, alpha);
        const room = root.isLight ? lc : 1 - lc;
        if (room <= 0.001)
            return Qt.alpha(c, alpha);
        // Blend toward extreme
        const t = Math.min(1, (target - delta) / room);
        const toward = root.isLight ? 0 : 1;
        return Qt.rgba(c.r + (toward - c.r) * t, c.g + (toward - c.g) * t, c.b + (toward - c.b) * t, alpha);
    }

    // Elevation direction
    readonly property bool isLight: root.luminance(background) > 0.5

    // Minimum separation
    readonly property real elevationFloor: 0.04

    // Measured wallpaper brightness
    property real wallLuminance: 0
    Behavior on wallLuminance { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // How hard brightness lifts cards
    readonly property real luminanceLift: 0.8

    // Panel background
    readonly property color panel: Config.appearance.transparency ? Qt.alpha(background, Config.appearance.panelOpacity) : background

    // Elevated fill at alpha
    function elevatedAt(alpha: real, alwaysAlpha: bool): color {
        const transparent = Config.appearance.transparency;
        // Must outrun a bright wallpaper
        const boost = 1 + root.wallLuminance * root.luminanceLift;
        const target = root.elevationFloor + (transparent ? 1.2 * (1 - Config.appearance.panelOpacity) * boost : 0);
        return root.elevate(background, surface, target, (transparent || alwaysAlpha) ? alpha : 1);
    }

    // Card fill
    readonly property color layer: root.elevatedAt(Config.appearance.layerOpacity, false)

    // Bar pill fill
    readonly property color pill: root.elevatedAt(Config.appearance.pillOpacity, true)

    // Card fill for free-floating popups
    readonly property color layerOpaque: root.elevate(background, surface, root.elevationFloor, 1)

    property color background: "#0f1417"
    Behavior on background { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color surface: "#1b2023"
    Behavior on surface { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color primary: "#8ad0ef"
    Behavior on primary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Series accents
    property color secondary: "#b4c9d7"
    Behavior on secondary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color tertiary: "#c8c0e8"
    Behavior on tertiary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // On-primary foreground
    property color textOnPrimary: "#003546"
    Behavior on textOnPrimary { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Tonal container
    property color secondaryContainer: "#37474f"
    Behavior on secondaryContainer { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Text roles
    property color text: "#dfe3e6"
    Behavior on text { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color textMuted: "#c0c8cd"
    Behavior on textMuted { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color outline: "#8a9297"
    Behavior on outline { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Divider outline
    property color outlineVariant: "#3f484c"
    Behavior on outlineVariant { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Error roles
    property color error: "#ffb4ab"
    Behavior on error { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color textOnError: "#690005"
    Behavior on textOnError { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color errorContainer: "#93000a"
    Behavior on errorContainer { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Recording red
    readonly property color recording: "#e64553"
}
