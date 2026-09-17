import "."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../services"
import "../../components"

// Media tab
Item {
    id: root

    readonly property bool hasLength: Media.length > 0
    readonly property string gifPath: {
        const configured = Directories.resolve(Config.dashboard.media.gifPath);
        return configured.length > 0 ? configured : Directories.bongocatGif;
    }

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
        spacing: Motion.spacing.large

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "\u{266A}"
            color: Colors.textMuted
            font.pixelSize: 56
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing playing"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.header
        }
    }

    // Has-media content
    RowLayout {
        id: hasMediaRow

        anchors.centerIn: parent
        visible: Media.hasPlayer
        spacing: 32

        CoverArt {
            Layout.alignment: Qt.AlignVCenter
            size: Config.dashboard.media.coverArtSize
        }

        // Title and transport
        ColumnLayout {
            Layout.preferredWidth: 360
            spacing: Motion.spacing.tiny

            StyledText {
                Layout.fillWidth: true
                text: Media.title.length > 0 ? Media.title : "Unknown title"
                font.pixelSize: Motion.fontSize.xlarge
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Media.artist.length > 0 ? Media.artist : "Unknown artist"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.title
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Media.album.length > 0 ? Media.album : "Unknown album"
                color: Colors.secondary
                font.pixelSize: Motion.fontSize.title
                elide: Text.ElideRight
            }

            // Seek row
            RowLayout {
                Layout.topMargin: Motion.spacing.section
                Layout.fillWidth: true
                spacing: Motion.spacing.normal

                TextMetrics {
                    id: timeMetrics

                    text: root.formatTime(Math.max(Media.position, Media.length)).replace(/[1-9]/g, "0")
                    font.family: Fonts.interfaceFamily
                    font.pixelSize: Motion.fontSize.body
                }

                StyledText {
                    Layout.preferredWidth: timeMetrics.width
                    text: root.formatTime(seek.dragging ? seek.displayValue * Media.length : Media.position)
                    color: Colors.textMuted
                    font.pixelSize: timeMetrics.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                }

                WavySlider {
                    id: seek

                    Layout.fillWidth: true
                    value: root.hasLength ? Media.position / Media.length : 0
                    enabled: (Media.activePlayer?.canSeek ?? false) && root.hasLength
                    animate: Media.isPlaying
                    onSeeked: position => {
                        const player = Media.activePlayer;
                        if (player && player.canSeek)
                            player.position = position * Media.length;
                    }
                }

                StyledText {
                    Layout.preferredWidth: timeMetrics.width
                    text: root.hasLength ? root.formatTime(Media.length) : "--:--"
                    color: Colors.textMuted
                    font.pixelSize: timeMetrics.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Transport controls
            RowLayout {
                Layout.topMargin: Motion.spacing.xlarge
                Layout.alignment: Qt.AlignHCenter
                spacing: Motion.spacing.medium

                MediaTransportButton {
                    glyph: "shuffle"
                    iconSize: 16
                    checked: Media.shuffle
                    enabled: Media.shuffleSupported
                    onClicked: Media.toggleShuffle()
                }

                MediaTransportButton {
                    glyph: "skip_previous"
                    enabled: Media.canGoPrevious
                    onClicked: Media.previous()
                }

                MediaTransportButton {
                    Layout.preferredWidth: 92
                    glyph: Media.isPlaying ? "pause" : "play_arrow"
                    filled: true
                    iconSize: 22
                    enabled: Media.canTogglePlaying
                    onClicked: Media.togglePlaying()
                }

                MediaTransportButton {
                    glyph: "skip_next"
                    enabled: Media.canGoNext
                    onClicked: Media.next()
                }

                MediaTransportButton {
                    glyph: Media.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                    iconSize: 16
                    checked: Media.loopState !== MprisLoopState.None
                    enabled: Media.loopSupported
                    onClicked: Media.cycleLoopState()
                }
            }
        }

        AnimatedImage {
            Layout.preferredWidth: Config.dashboard.media.coverArtSize
            Layout.preferredHeight: Config.dashboard.media.coverArtSize
            Layout.alignment: Qt.AlignVCenter
            visible: Config.dashboard.media.gifEnabled
            source: "file://" + root.gifPath
            speed: Config.dashboard.media.gifSpeed
            playing: Config.dashboard.media.gifEnabled
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
    }

    // Click-outside catcher
    MouseArea {
        anchors.fill: parent
        visible: playerSelector.menuOpen
        onClicked: playerSelector.closeMenu()
    }

    MediaPlayerSelector {
        id: playerSelector

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Motion.spacing.xlarge
    }
}
