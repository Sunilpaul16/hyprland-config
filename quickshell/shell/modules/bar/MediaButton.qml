import QtQuick
import "../../services"

// Media player icon + track title, opens MediaPopup
Item {
    id: root

    readonly property int maxTitleWidth: 160

    visible: Media.hasPlayer
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Media.isPlaying ? "\u{23F8}" : "\u{25B6}" // pause / play
            color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: 12

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTitleWidth)
            text: Media.artist.length > 0 ? `${Media.title} · ${Media.artist}` : Media.title
            color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: 13
            elide: Text.ElideRight

            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: MediaState.toggle()
    }
}
