import QtQuick

// Quick toggle definition
NestableObject {
    required property string toggleId
    required property string icon
    property string name: ""
    property bool toggled: false
    // Backend availability
    property bool available: true
    required property var mainAction
    property var altAction: null
}
