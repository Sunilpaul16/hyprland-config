import QtQuick
import "../"

// One keycap-style chip -- themed like Workspaces.qml's pills (Colors.surface
// fill, rounded, Colors.text label) rather than a flat text label, so a key
// combo reads visually distinct from its description next to it.
Rectangle {
    id: root

    required property string label

    implicitWidth: Math.max(text.implicitWidth + 14, height)
    implicitHeight: 20
    radius: 6
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Text {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: Colors.text
        font.pixelSize: 11
        font.bold: true
    }
}
