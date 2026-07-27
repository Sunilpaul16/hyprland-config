pragma Singleton
import QtQuick

// Animation timing singleton
QtObject {
    id: root

    // Config-driven speed. Clamped because this divides every duration in the
    // shell — a stray 0 in config.json would otherwise make each one Infinity
    readonly property real speed: Math.min(4, Math.max(0.25, Config.motion.speed))
    readonly property bool reduced: Config.motion.reduced

    // Base ms -> effective ms. `reduced` collapses to 0 here rather than each
    // animation gating itself: a 0ms animation still runs and still fires its
    // completion handlers, so nothing downstream needs a reduced-motion branch
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
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]

        readonly property int expressiveFastSpatialDuration: root.scaled(350)
        readonly property int expressiveDefaultSpatialDuration: root.scaled(500)
        readonly property int expressiveSlowSpatialDuration: root.scaled(650)
        readonly property int expressiveEffectsDuration: root.scaled(200)
    }

    // Corner-radius tokens — matched to this repo's actual in-use values
    // (18 is overwhelmingly the most common card radius already)
    readonly property QtObject rounding: QtObject {
        readonly property int small: 8
        readonly property int normal: 13
        readonly property int large: 18
    }
}
