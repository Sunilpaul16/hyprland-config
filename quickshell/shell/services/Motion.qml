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

    // Shared easing curve
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

    // Font size ladder
    readonly property QtObject fontSize: QtObject {
        readonly property int micro: 9  // badge counts
        readonly property int tiny: 10  // dense secondary meta
        readonly property int small: 11  // captions, muted labels
        readonly property int body: 12  // default body text
        readonly property int label: 13  // list-item titles
        readonly property int subhead: 14  // section labels
        readonly property int title: 15  // card titles
        readonly property int large: 16  // panel, page titles
        readonly property int header: 18  // prominent headers
        readonly property int display: 20  // dashboard figures
        readonly property int xlarge: 22  // largest text
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
