import "../"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../../services"

// Condensed media summary card — cover art (progress arc wraps it), title/album/artist, transport controls, gif
Rectangle {
    id: root

    readonly property real progress: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : 0
    readonly property string gifPath: {
        const configured = Directories.resolve(Config.dashboard.media.gifPath);
        return configured.length > 0 ? configured : Directories.bongocatGif;
    }

    // Tonal container fill for the outer transport buttons
    readonly property color tonalBg: Qt.tint(Colors.surface, Qt.alpha(Colors.primary, 0.28))

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline
    clip: true
    implicitHeight: content.implicitHeight + 32

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Cover art, wrapped in a playback-progress arc (caelestia's dash Media widget)
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

                            Behavior on sweepAngle { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                visible: Media.hasPlayer
                horizontalAlignment: Text.AlignHCenter
                text: Media.title.length > 0 ? Media.title : "Unknown title"
                color: Colors.text
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: Media.hasPlayer && Media.album.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: Media.album
                color: Colors.outline
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: Media.hasPlayer && Media.artist.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: Media.artist
                color: Colors.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: !Media.hasPlayer
                horizontalAlignment: Text.AlignHCenter
                text: "Nothing playing"
                color: Colors.textMuted
                font.pixelSize: 12
            }
        }

        // Transport controls
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6

            TransportButton {
                glyph: "skip_previous"
                enabled: Media.canGoPrevious
                onClicked: Media.previous()
            }

            TransportButton {
                Layout.fillWidth: true
                glyph: Media.isPlaying ? "pause" : "play_arrow"
                enabled: Media.canTogglePlaying
                filled: true
                onClicked: Media.togglePlaying()
            }

            TransportButton {
                glyph: "skip_next"
                enabled: Media.canGoNext
                onClicked: Media.next()
            }
        }

        // Fills the leftover column space rather than leaving a dead gap
        AnimatedImage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 6
            visible: Config.dashboard.media.gifEnabled
            source: "file://" + root.gifPath
            speed: Config.dashboard.media.gifSpeed
            playing: Media.isPlaying
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Item {
            Layout.fillHeight: true
            visible: !Config.dashboard.media.gifEnabled
        }
    }

    // Tonal circle for prev/next, filled pill for play/pause (caelestia's IconButton Tonal vs fillWidth)
    component TransportButton: Rectangle {
        id: btn

        property string glyph: ""
        property bool filled: false
        signal clicked()

        implicitWidth: 34
        implicitHeight: 34
        radius: height / 2
        color: btn.filled ? Colors.primary : (area.containsMouse ? Qt.tint(root.tonalBg, Qt.alpha(Colors.primary, 0.18)) : root.tonalBg)
        opacity: btn.enabled ? 1 : 0.35

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            color: btn.filled ? Colors.background : Colors.primary
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
