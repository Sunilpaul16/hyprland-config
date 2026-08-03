pragma Singleton
import QtQuick

// Animation timing, plus the corner-radius, font-size and gap ladders every module sizes against
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

    // Text size ladder, 9-22 — same rule as rounding: pick an existing step rather than a raw literal
    // Display numerals (the dashboard clock, hero temperatures) stay off-ladder and Config-driven, since they scale with their card rather than with body text
    readonly property QtObject fontSize: QtObject {
        readonly property int micro: 9     // badge counts, the densest meta
        readonly property int tiny: 10     // dense secondary meta
        readonly property int small: 11    // captions and muted secondary labels
        readonly property int body: 12     // default body text, the most common size
        readonly property int label: 13    // list-item titles and emphasised body
        readonly property int subhead: 14  // section labels
        readonly property int title: 15    // card titles
        readonly property int large: 16    // panel and page titles
        readonly property int header: 18   // prominent headers
        readonly property int display: 20  // dashboard figures
        readonly property int xlarge: 22   // the largest non-numeral text
    }

    // Gap ladder, 2-24 — covers spacing, padding and margins alike; same rule again, pick a step rather than a raw literal
    // 0 stays a literal: it means "no gap", never a tunable one
    readonly property QtObject spacing: QtObject {
        readonly property int micro: 2    // hairline gaps inside a chip or badge
        readonly property int tiny: 4     // icon-to-label, dense inner rows
        readonly property int small: 6    // between small inner elements
        readonly property int normal: 8   // the default gap between siblings, the most common
        readonly property int medium: 10  // roomier inner grouping
        readonly property int large: 12   // between cards in a column
        readonly property int wide: 14    // generous card padding
        readonly property int xlarge: 16  // panel edge padding and top-level insets
        readonly property int section: 24 // between major sections of a page
    }
}
