import "../"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../../services"

// Condensed media summary card — cover art (progress arc wraps it), title/artist, transport controls
Rectangle {
    id: root

    readonly property real progress: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : 0

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline
    clip: true

    ColumnLayout {
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
                width: cover.width + Config.dashboardMediaProgressThickness * 2 + 4
                height: width

                Shape {
                    anchors.fill: parent
                    asynchronous: true
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: Config.dashboardMediaProgressThickness
                        strokeColor: Colors.primary
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: progressArc.width / 2
                            centerY: progressArc.height / 2
                            radiusX: (progressArc.width - Config.dashboardMediaProgressThickness) / 2
                            radiusY: radiusX
                            startAngle: -90 - Config.dashboardMediaProgressSweep / 2
                            sweepAngle: Config.dashboardMediaProgressSweep * root.progress

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

        Item { Layout.fillHeight: true }

        // Transport controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            TransportButton {
                glyph: "\u{23EE}"
                enabled: Media.canGoPrevious
                onClicked: Media.previous()
            }

            TransportButton {
                glyph: Media.isPlaying ? "\u{23F8}" : "\u{25B6}"
                enabled: Media.canTogglePlaying
                big: true
                onClicked: Media.togglePlaying()
            }

            TransportButton {
                glyph: "\u{23ED}"
                enabled: Media.canGoNext
                onClicked: Media.next()
            }
        }
    }

    component TransportButton: Item {
        id: btn

        property string glyph: ""
        property bool big: false
        signal clicked()

        implicitWidth: icon.implicitWidth
        implicitHeight: icon.implicitHeight
        opacity: btn.enabled ? 1 : 0.35

        Text {
            id: icon
            text: btn.glyph
            color: area.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: btn.big ? 18 : 14

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
}
