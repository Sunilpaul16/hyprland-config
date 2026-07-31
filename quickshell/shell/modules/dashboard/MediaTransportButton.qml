import QtQuick
import "../../services"
import "../../components"

// Prev/play-pause/next glyph button; `big` sizes up the centre one
Item {
    id: btn

    property string glyph: ""
    property bool big: false
    signal clicked()

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    opacity: btn.enabled ? 1 : 0.35

    StyledText {
        id: icon
        text: btn.glyph
        color: area.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: btn.big ? 26 : 18

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
