pragma Singleton
import QtQuick

// Animation timing singleton
QtObject {
    id: root

    // quick — hover/press feedback (colors, small opacity/size nudges)
    readonly property int quickDuration: 110
    readonly property int quickEasing: Easing.OutCubic
    readonly property Component quickNumberAnimation: Component {
        NumberAnimation { duration: root.quickDuration; easing.type: root.quickEasing }
    }
    readonly property Component quickColorAnimation: Component {
        ColorAnimation { duration: root.quickDuration; easing.type: root.quickEasing }
    }

    // smooth — panel/overlay show-hide (the showProgress pattern)
    readonly property int smoothDuration: 160
    readonly property int smoothEasing: Easing.OutCubic
    readonly property Component smoothNumberAnimation: Component {
        NumberAnimation { duration: root.smoothDuration; easing.type: root.smoothEasing }
    }
    readonly property Component smoothColorAnimation: Component {
        ColorAnimation { duration: root.smoothDuration; easing.type: root.smoothEasing }
    }

    // deliberate — layout/resize/reflow (pill movement, panel resize, list reflow)
    readonly property int deliberateDuration: 200
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

        readonly property int expressiveFastSpatialDuration: 350
        readonly property int expressiveDefaultSpatialDuration: 500
        readonly property int expressiveSlowSpatialDuration: 650
        readonly property int expressiveEffectsDuration: 200
    }

    // Corner-radius tokens — matched to this repo's actual in-use values
    // (18 is overwhelmingly the most common card radius already)
    readonly property QtObject rounding: QtObject {
        readonly property int small: 8
        readonly property int normal: 13
        readonly property int large: 18
    }
}
