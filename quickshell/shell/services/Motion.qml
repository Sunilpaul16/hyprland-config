pragma Singleton
import QtQuick

// Motion tokens
QtObject {
    id: root

    // Speed multiplier
    readonly property real speed: Math.min(4, Math.max(0.25, Config.motion.speed))
    readonly property bool reduced: Config.motion.reduced

    // Scale duration
    function scaled(ms: int): int {
        return root.reduced ? 0 : Math.round(ms / root.speed);
    }

    // quick — hover/press
    readonly property int quickDuration: root.scaled(110)
    readonly property int quickEasing: Easing.OutCubic

    // smooth — show/hide
    readonly property int smoothDuration: root.scaled(160)
    readonly property int smoothEasing: Easing.OutCubic

    // deliberate — layout/resize
    readonly property int deliberateDuration: root.scaled(200)
    readonly property int deliberateEasing: Easing.OutCubic

    // Qt's BezierSpline format is x1,y1,x2,y2 followed by the 1,1 endpoint.
    readonly property list<real> curve: [0.34, 0.80, 0.34, 1.00, 1, 1]

    // Motion durations
    readonly property var anim: ({
        enter: 350,
        exit: 220,
        spatial: 300,
        effects: 200,
        effectsFast: 150
    })

    // Rounding ladder
    readonly property QtObject rounding: QtObject {
        readonly property int tiny: 6  // tray, menu rows
        readonly property int small: 8  // chips, small buttons
        readonly property int item: 10  // list, grid items
        readonly property int normal: 12  // toggles, pills
        readonly property int card: 14  // cards, dropdowns
        readonly property int nested: 16  // nested cards
        readonly property int large: 18  // top-level cards
        readonly property int drawer: 20  // drawers, dialogs
        readonly property int page: 22  // settings page cards
        readonly property int hero: 26  // hero, performance cards
    }

    // Concave fillet at a panel joint
    readonly property int cornerSize: 14

    // Convert the system point size to logical pixels; compositor scaling applies separately.
    readonly property real textScale: Config.appearance.shellFollowSystemFont
        ? Math.max(8, Math.min(20, Config.appearance.fontSize)) / 9 : 1

    // Font size ladder
    readonly property QtObject fontSize: QtObject {
        readonly property int micro: Math.round(9 * root.textScale)  // badge counts
        readonly property int tiny: Math.round(10 * root.textScale)  // dense secondary meta
        readonly property int small: Math.round(11 * root.textScale)  // captions, muted labels
        readonly property int body: Math.round(12 * root.textScale)  // default body text
        readonly property int label: Math.round(13 * root.textScale)  // list-item titles
        readonly property int subhead: Math.round(14 * root.textScale)  // section labels
        readonly property int title: Math.round(15 * root.textScale)  // card titles
        readonly property int large: Math.round(16 * root.textScale)  // panel, page titles
        readonly property int header: Math.round(18 * root.textScale)  // prominent headers
        readonly property int display: Math.round(20 * root.textScale)  // dashboard figures
        readonly property int xlarge: Math.round(22 * root.textScale)  // largest text
    }

    // Gap ladder
    readonly property QtObject spacing: QtObject {
        readonly property int micro: 2  // hairline gaps
        readonly property int tiny: 4  // icon-to-label
        readonly property int small: 6  // small inner elements
        readonly property int normal: 8  // default sibling gap
        readonly property int medium: 10  // roomier grouping
        readonly property int large: 12  // between cards
        readonly property int wide: 14  // generous card padding
        readonly property int xlarge: 16  // panel edge padding
        readonly property int section: 24  // between page sections
    }
}
