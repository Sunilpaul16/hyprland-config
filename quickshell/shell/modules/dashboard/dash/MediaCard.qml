import "../"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../../services"
import "../../../components"

// Condensed media card
Rectangle {
    id: root

    readonly property real progress: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : 0
    readonly property string gifPath: {
        const configured = Directories.resolve(Config.dashboard.media.gifPath);
        return configured.length > 0 ? configured : Directories.bongocatGif;
    }

    radius: Motion.rounding.large
    color: Colors.layer
    border.width: 1
    border.color: Colors.outlineVariant
    clip: true
    implicitHeight: content.implicitHeight + 32

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Motion.spacing.xlarge
        spacing: Motion.spacing.medium

        // Cover art arc
        Item {
            id: coverWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: progressArc.width
            implicitHeight: progressArc.height

            CoverArt {
                id: cover

                anchors.centerIn: parent
                size: Math.min(root.width - 32, 140)
            }

            Item {
                id: progressArc

                anchors.centerIn: cover
                visible: Media.hasPlayer
                width: cover.width + Config.dashboard.media.progressThickness * 2 + 4
                height: width

                Shape {
                    anchors.fill: parent
                    asynchronous: true
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: Config.dashboard.media.progressThickness
                        strokeColor: Colors.primary
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: progressArc.width / 2
                            centerY: progressArc.height / 2
                            radiusX: (progressArc.width - Config.dashboard.media.progressThickness) / 2
                            radiusY: radiusX
                            startAngle: -90 - Config.dashboard.media.progressSweep / 2
                            sweepAngle: Config.dashboard.media.progressSweep * root.progress

                            Behavior on sweepAngle { NumberAnimation { duration: Motion.scaled(300); easing.type: Easing.OutSine } }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Motion.spacing.micro

            StyledText {
                Layout.fillWidth: true
                visible: Media.hasPlayer
                horizontalAlignment: Text.AlignHCenter
                text: Media.title.length > 0 ? Media.title : "Unknown title"
                font.pixelSize: Motion.fontSize.label
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: Media.hasPlayer && Media.album.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: Media.album
                color: Colors.outline
                font.pixelSize: Motion.fontSize.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: Media.hasPlayer && Media.artist.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: Media.artist
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: !Media.hasPlayer
                horizontalAlignment: Text.AlignHCenter
                text: "Nothing playing"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
            }
        }

        // Transport controls
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Motion.spacing.tiny
            spacing: Motion.spacing.small

            MediaTransportButton {
                glyph: "skip_previous"
                enabled: Media.canGoPrevious
                onClicked: Media.previous()
            }

            MediaTransportButton {
                Layout.fillWidth: true
                glyph: Media.isPlaying ? "pause" : "play_arrow"
                enabled: Media.canTogglePlaying
                filled: true
                onClicked: Media.togglePlaying()
            }

            MediaTransportButton {
                glyph: "skip_next"
                enabled: Media.canGoNext
                onClicked: Media.next()
            }
        }

        // Fills leftover space
        AnimatedImage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Motion.spacing.small
            visible: Config.dashboard.media.gifEnabled
            source: "file://" + root.gifPath
            speed: Config.dashboard.media.gifSpeed
            playing: Media.isPlaying
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        // Gif placeholder
        Item {
            Layout.fillHeight: true
            visible: !Config.dashboard.media.gifEnabled
        }
    }
}
