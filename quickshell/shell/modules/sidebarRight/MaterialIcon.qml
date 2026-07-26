import QtQuick

// Material Symbols Rounded glyph — set `text` to the icon's name (e.g.
// "wifi", "settings"); the font's ligature table swaps the name for the
// glyph. Needs ttf-material-symbols-variable installed system-wide (not
// bundled in this repo).
Text {
    id: root

    // Variable font's FILL axis: 0 = outlined, 1 = solid. Animatable
    property real fill: 0

    font.family: "Material Symbols Rounded"
    font.variableAxes: ({ "FILL": root.fill.toFixed(2) })
}
