import QtQuick

// Declarative quick-toggle definition (comparison.md #24)
NestableObject {
    required property string toggleId
    required property string icon
    property string name: ""
    property bool toggled: false
    // Backend present but temporarily unavailable (e.g. no Bluetooth adapter), vs. no entry at all
    property bool available: true
    required property var mainAction
    property var altAction: null
}
