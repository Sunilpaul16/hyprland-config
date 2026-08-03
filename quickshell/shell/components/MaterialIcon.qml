import QtQuick

// Material Symbols glyph
Text {
    id: root

    // FILL axis
    property real fill: 0

    font.family: "Material Symbols Rounded"
    font.variableAxes: ({ "FILL": root.fill.toFixed(2) })
}
