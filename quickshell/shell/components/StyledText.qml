import QtQuick
import "../services"

// Every piece of text in the shell, so the configured interface font reaches all of it — plain Items and Texts take no part in Qt's font inheritance
// Deliberately carries only family and colour; sizes and weights stay explicit at each call site
Text {
    font.family: Fonts.interfaceFamily
    color: Colors.text
}
