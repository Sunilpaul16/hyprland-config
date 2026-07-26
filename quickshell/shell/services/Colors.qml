pragma Singleton
import QtQuick

// Hand-written, NOT matugen-generated — matugen instead writes
// ~/.local/state/quickshell/colors.json, and ColorsLoader.qml mutates the
// properties below at runtime (see [templates.quickshell_colors_json] in
// matugen/config.toml). This keeps Colors.qml out of the hot-reloaded
// shell tree, so a wallpaper change cross-fades via the Behaviors below
// instead of restarting the whole shell. Values here are last-known-good
// defaults, used until the first ColorsLoader.reapplyTheme() completes.
QtObject {
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

    // Error / destructive roles (M3 error, onError, errorContainer,
    // onErrorContainer). Same on<Capital> rename as text/textMuted above:
    // the two foreground colors become textOnError/textOnErrorContainer.
    property color error: "#ffb4ab"
    Behavior on error { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color textOnError: "#690005"
    Behavior on textOnError { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color errorContainer: "#93000a"
    Behavior on errorContainer { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    property color textOnErrorContainer: "#ffdad6"
    Behavior on textOnErrorContainer { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
}
