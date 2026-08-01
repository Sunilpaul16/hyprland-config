import QtQuick

// Material Symbols Rounded glyph — set `text` to the icon name and the font's ligature table swaps it for the glyph; needs ttf-material-symbols-variable installed
Text {
    id: root

    // Variable font's FILL axis: 0 = outlined, 1 = solid. Animatable
    property real fill: 0

    font.family: "Material Symbols Rounded"
    font.variableAxes: ({ "FILL": root.fill.toFixed(2) })
}
