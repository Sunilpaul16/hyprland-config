pragma Singleton
import QtQuick

// Animation timing singleton
QtObject {
    id: root

    // Config-driven speed. Clamped because this divides every duration in the
    // shell — a stray 0 in config.json would otherwise make each one Infinity
    readonly property real speed: Math.min(4, Math.max(0.25, Config.motion.speed))
    readonly property bool reduced: Config.motion.reduced

    // Base ms -> effective ms; `reduced` collapses to 0 here so nothing downstream needs its own branch (a 0ms animation still fires its handlers)
    function scaled(ms: int): int {
        return root.reduced ? 0 : Math.round(ms / root.speed);
    }

    // quick — hover/press feedback (colors, small opacity/size nudges)
    readonly property int quickDuration: root.scaled(110)
    readonly property int quickEasing: Easing.OutCubic
    readonly property Component quickNumberAnimation: Component {
        NumberAnimation { duration: root.quickDuration; easing.type: root.quickEasing }
    }
    readonly property Component quickColorAnimation: Component {
        ColorAnimation { duration: root.quickDuration; easing.type: root.quickEasing }
    }

    // smooth — panel/overlay show-hide (the showProgress pattern)
    readonly property int smoothDuration: root.scaled(160)
    readonly property int smoothEasing: Easing.OutCubic
    readonly property Component smoothNumberAnimation: Component {
        NumberAnimation { duration: root.smoothDuration; easing.type: root.smoothEasing }
    }
    readonly property Component smoothColorAnimation: Component {
        ColorAnimation { duration: root.smoothDuration; easing.type: root.smoothEasing }
    }

    // deliberate — layout/resize/reflow (pill movement, panel resize, list reflow)
    readonly property int deliberateDuration: root.scaled(200)
    readonly property int deliberateEasing: Easing.OutCubic
    readonly property Component deliberateNumberAnimation: Component {
        NumberAnimation { duration: root.deliberateDuration; easing.type: root.deliberateEasing }
    }
    readonly property Component deliberateColorAnimation: Component {
        ColorAnimation { duration: root.deliberateDuration; easing.type: root.deliberateEasing }
    }

    // M3 Expressive bezier curves — for use with easing.type: Easing.BezierSpline
    // + easing.bezierCurve: Motion.animationCurves.<name>
    readonly property QtObject animationCurves: QtObject {
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
        readonly property int expressiveDefaultSpatialDuration: root.scaled(500)
    }

    // Corner radius ladder, 6-26 — names say where each step is used; pick an existing one rather than introducing a new value
    readonly property QtObject rounding: QtObject {
        readonly property int tiny: 6    // tray and menu rows, the smallest inner fills
        readonly property int small: 8   // chips, small buttons, inner elements
        readonly property int item: 10   // launcher and overview list/grid items
        readonly property int normal: 12 // toggles, pills, inner menu rows
        readonly property int card: 14   // notification cards, dropdown surfaces
        readonly property int nested: 16 // cards nested inside a dashboard tab
        readonly property int large: 18  // top-level cards and panels
        readonly property int drawer: 20 // slide-in drawers and the dialogs that match them
        readonly property int page: 22   // settings page cards
        readonly property int hero: 26   // dashboard hero and performance cards
    }
}
