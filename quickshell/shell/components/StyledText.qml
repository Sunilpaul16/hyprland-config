import QtQuick
import "../services"

// Every piece of text in the shell. Exists so the configured interface font
// reaches all of it — plain Items and Texts take no part in Qt's font
// inheritance, so a family set anywhere else reaches exactly one label.
//
// Deliberately carries only family and colour. Sizes and weights stay explicit
// at each call site
Text {
    font.family: Fonts.interfaceFamily
    color: Colors.text
}
