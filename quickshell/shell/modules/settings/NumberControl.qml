import QtQuick
import QtQuick.Layouts

// Numeric setting control — readout plus a slider. Externally driven like the
// controls it wraps: dragging emits moved(), the owner writes the value back
RowLayout {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property int decimals: 0
    property string suffix: ""
    // Readout multiplier — lets a 0..1 property display as a percentage
    // without the slider having to work in different units
    property real displayScale: 1
    // Fixed so the slider doesn't shift sideways as the digits change. Wide
    // enough for the longest value any row uses ("15000 ms") — ValueLabel
    // elides, so too narrow silently truncates rather than overflowing
    property int labelWidth: 78

    signal moved(real v)

    spacing: 12

    ValueLabel {
        Layout.preferredWidth: root.labelWidth
        horizontalAlignment: Text.AlignRight
        text: (root.value * root.displayScale).toFixed(root.decimals) + root.suffix
    }

    SettingSlider {
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onMoved: v => root.moved(v)
    }
}
