import QtQuick
import QtQuick.Layouts
import "../../services"

// Numeric control
RowLayout {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property int decimals: 0
    property string suffix: ""
    // Readout multiplier
    property real displayScale: 1
    // Readout override
    property string displayText: ""
    // Readout width ceiling; callers can still override it.
    property int labelWidth: 78

    signal moved(real v)

    spacing: Motion.spacing.large
    Layout.fillWidth: true
    Layout.minimumWidth: 0

    ValueLabel {
        Layout.minimumWidth: 0
        Layout.maximumWidth: root.labelWidth
        Layout.preferredWidth: Math.min(root.labelWidth,
            Math.max(48, implicitWidth))
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
