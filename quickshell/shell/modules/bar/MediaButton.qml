import QtQuick
import "../../services"
import "../../components"

// Media player icon + track title
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
        spacing: 6

        StyledText {
            id: playPauseIcon
            anchors.verticalCenter: parent.verticalCenter
            text: Media.isPlaying ? "\u{23F8}" : "\u{25B6}" // pause / play
            color: (hoverArea.containsMouse || playPauseHover.containsMouse) ? Colors.text : Colors.textMuted
            font.pixelSize: 12

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            // Higher-z hit target so this glyph actually toggles playback, not just opens the popup
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
            font.pixelSize: 13
            elide: Text.ElideRight

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }
    }

    // Hover tracking for the label colors
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
