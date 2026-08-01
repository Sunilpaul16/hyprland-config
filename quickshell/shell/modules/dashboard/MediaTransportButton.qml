import QtQuick
import "../../services"
import "../../components"

// Transport button — tonal circle by default, accent-filled for play/pause
// (`filled`) and for an engaged shuffle/loop toggle (`checked`)
Rectangle {
    id: btn

    property string glyph: ""
    property bool filled: false
    property bool checked: false
    property int size: 34
    property int iconSize: 18
    signal clicked()

    readonly property color tonalBg: Colors.tint(Colors.surface, Colors.primary, 0.28)
    readonly property bool accented: btn.filled || btn.checked

    implicitWidth: btn.size
    implicitHeight: btn.size
    radius: height / 2
    color: btn.accented ? Colors.primary : (area.containsMouse ? Colors.tint(btn.tonalBg, Colors.primary, 0.18) : btn.tonalBg)
    opacity: btn.enabled ? 1 : 0.35

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        anchors.centerIn: parent
        text: btn.glyph
        font.pixelSize: btn.iconSize
        color: btn.accented ? Colors.background : Colors.primary

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
