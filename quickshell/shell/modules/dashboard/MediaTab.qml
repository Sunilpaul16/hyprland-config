import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../services"

// Media tab: full-page now-playing — cover art, draggable seek, transport controls
Item {
    id: root


    implicitWidth: (Media.hasPlayer ? hasMediaRow.implicitWidth : emptyState.implicitWidth) + 64
    implicitHeight: (Media.hasPlayer ? hasMediaRow.implicitHeight : emptyState.implicitHeight) + 64

    function formatTime(seconds: real): string {
        if (!seconds || seconds < 0 || isNaN(seconds))
            return "0:00";
        const total = Math.floor(seconds);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    // No-media empty state
    ColumnLayout {
        id: emptyState

        anchors.centerIn: parent
        visible: !Media.hasPlayer
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\u{266A}"
            color: Colors.textMuted
            font.pixelSize: 56
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing playing"
            color: Colors.textMuted
            font.pixelSize: 18
        }
    }

    // Has-media content
    RowLayout {
        id: hasMediaRow

        anchors.centerIn: parent
        visible: Media.hasPlayer
        spacing: 32

        // Cover art
        CoverArt {
            size: Config.dashboard.media.coverArtSize
        }

        // Info + seek + controls
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: Media.title.length > 0 ? Media.title : "Unknown title"
                color: Colors.text
                font.pixelSize: 22
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: Media.artist.length > 0 ? Media.artist : "Unknown artist"
                color: Colors.textMuted
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            Item { Layout.preferredHeight: 20 }

            // Draggable seek slider — writes straight to the MPRIS player
            // object Media.qml already exposes (Media.qml itself has no
            // seek/write API, and isn't being extended for it this session)
            Slider {
                id: seekSlider

                Layout.fillWidth: true

                from: 0
                to: 1
                value: Media.length > 0 ? Media.position / Media.length : 0
                enabled: Media.activePlayer?.canSeek ?? false

                onPressedChanged: {
                    if (pressed)
                        return;
                    const player = Media.activePlayer;
                    if (player && player.canSeek)
                        player.position = seekSlider.value * Media.length;
                    seekSlider.value = Qt.binding(() => Media.length > 0 ? Media.position / Media.length : 0);
                }

                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    width: seekSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Colors.layer

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Colors.primary
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 14
                    implicitHeight: 14
                    radius: width / 2
                    color: seekSlider.pressed ? Colors.text : Colors.primary
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: -4

                Text {
                    text: root.formatTime(Media.position)
                    color: Colors.textMuted
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatTime(Media.length)
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }

            Item { Layout.preferredHeight: 16 }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                MediaToggleButton {
                    iconName: "shuffle"
                    active: Media.shuffle
                    visible: Media.shuffleSupported
                    onClicked: Media.toggleShuffle()
                }

                MediaTransportButton {
                    glyph: "\u{23EE}"
                    enabled: Media.canGoPrevious
                    onClicked: Media.previous()
                }

                MediaTransportButton {
                    glyph: Media.isPlaying ? "\u{23F8}" : "\u{25B6}"
                    enabled: Media.canTogglePlaying
                    big: true
                    onClicked: Media.togglePlaying()
                }

                MediaTransportButton {
                    glyph: "\u{23ED}"
                    enabled: Media.canGoNext
                    onClicked: Media.next()
                }

                MediaToggleButton {
                    iconName: Media.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                    active: Media.loopState !== MprisLoopState.None
                    visible: Media.loopSupported
                    onClicked: Media.cycleLoopState()
                }
            }
        }
    }

    // Click-outside catcher for the player-menu dropdown
    MouseArea {
        anchors.fill: parent
        visible: playerSelector.menuOpen
        onClicked: playerSelector.closeMenu()
    }

    MediaPlayerSelector {
        id: playerSelector

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
    }
}
