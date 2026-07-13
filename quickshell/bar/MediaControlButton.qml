import QtQuick

// Small capability-gated media control glyph button (dimmed, not hidden,
// when the active player doesn't support the action)
Item {
    id: root

    property string glyph: ""
    property bool big: false
    signal clicked

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    opacity: root.enabled ? 1 : 0.35

    Text {
        id: icon
        text: root.glyph
        color: area.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: root.big ? 16 : 13

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
