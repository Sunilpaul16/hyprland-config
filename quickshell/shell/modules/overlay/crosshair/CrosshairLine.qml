import QtQuick

// Outlined crosshair line
Rectangle {
    id: root

    property bool horizontal: false
    property int thickness: 2
    property int length: 8
    property bool outline: true
    property color lineColor: "#00ff66"

    readonly property int pad: root.outline ? 2 : 0

    implicitWidth: (root.horizontal ? root.length : root.thickness) + root.pad
    implicitHeight: (root.horizontal ? root.thickness : root.length) + root.pad
    color: root.outline ? "#000000" : "transparent"

    Rectangle {
        anchors.centerIn: parent
        width: root.horizontal ? root.length : root.thickness
        height: root.horizontal ? root.thickness : root.length
        color: root.lineColor
    }
}
