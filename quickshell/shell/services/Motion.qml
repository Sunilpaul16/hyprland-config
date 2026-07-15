pragma Singleton
import QtQuick

// Animation timing singleton
QtObject {
    // quick — hover/press feedback (colors, small opacity/size nudges)
    readonly property int quickDuration: 110
    readonly property int quickEasing: Easing.OutCubic

    // smooth — panel/overlay show-hide (the showProgress pattern)
    readonly property int smoothDuration: 160
    readonly property int smoothEasing: Easing.OutCubic

    // deliberate — layout/resize/reflow (pill movement, panel resize, list reflow)
    readonly property int deliberateDuration: 200
    readonly property int deliberateEasing: Easing.OutCubic
}
