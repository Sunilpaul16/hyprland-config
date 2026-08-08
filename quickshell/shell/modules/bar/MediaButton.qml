import QtQuick
import "../../services"
import "../../components"

// Media button
Item {
    id: root

    readonly property int maxTitleWidth: 160

    visible: Media.hasPlayer
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    // Icon + title
    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Motion.spacing.small

        StyledText {
            id: playPauseIcon
            anchors.verticalCenter: parent.verticalCenter
            text: Media.isPlaying ? "\u{23F8}" : "\u{25B6}" // pause / play
            color: (hoverArea.containsMouse || playPauseHover.containsMouse) ? Colors.text : Colors.textMuted
            font.pixelSize: Motion.fontSize.body

            Behavior on color { CAnim {} }

            // Playback hit target
            MouseArea {
                id: playPauseHover
                anchors.fill: parent
                anchors.margins: -4
                z: 1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.togglePlaying()
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTitleWidth)
            text: Media.artist.length > 0 ? `${Media.title} · ${Media.artist}` : Media.title
            color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: Motion.fontSize.label
            elide: Text.ElideRight

            Behavior on color { CAnim {} }
        }
    }

    // Hover tracking
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
