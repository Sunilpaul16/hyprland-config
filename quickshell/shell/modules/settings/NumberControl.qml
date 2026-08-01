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
    // Replaces the computed readout when set — for a value whose units aren't a
    // plain suffix, like an interval read out as hours and minutes
    property string displayText: ""
    // Fixed so the slider doesn't shift as digits change, and wide enough for "15000 ms" — ValueLabel elides, so too narrow truncates silently
    property int labelWidth: 78

    signal moved(real v)

    spacing: 12

    ValueLabel {
        Layout.preferredWidth: root.labelWidth
        horizontalAlignment: Text.AlignRight
        text: root.displayText.length > 0
            ? root.displayText
            : (root.value * root.displayScale).toFixed(root.decimals) + root.suffix
    }

    SettingSlider {
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onMoved: v => root.moved(v)
    }
}
