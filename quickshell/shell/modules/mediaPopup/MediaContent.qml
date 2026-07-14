import QtQuick
import QtQuick.Layouts
import "../../services"

// Media popup content: cover art + title/artist + progress + controls
Item {
    id: root

    readonly property int artSize: 88
    readonly property int infoWidth: 200
    readonly property real progress: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : 0

    // mm:ss formatter
    function formatTime(seconds: real): string {
        if (!seconds || seconds < 0 || isNaN(seconds))
            return "0:00";
        const total = Math.floor(seconds);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: Math.max(root.artSize, layout.implicitHeight)

    RowLayout {
        id: layout
        spacing: 14

        // Cover art
        Rectangle {
            Layout.preferredWidth: root.artSize
            Layout.preferredHeight: root.artSize
            radius: 12
            color: Colors.surface
            clip: true

            Image {
                anchors.fill: parent
                visible: Media.artSource.length > 0
                source: Media.artSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            // Flat monochrome fallback glyph, not a colorful emoji
            Text {
                anchors.centerIn: parent
                visible: Media.artSource.length === 0
                text: "\u{266A}" // eighth note
                color: Colors.textMuted
                font.pixelSize: 32
            }
        }

        // Info + controls
        ColumnLayout {
            Layout.preferredWidth: root.infoWidth
            Layout.fillHeight: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                visible: Media.hasPlayer
                text: Media.title.length > 0 ? Media.title : "Unknown title"
                color: Colors.text
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: Media.hasPlayer && Media.artist.length > 0
                text: Media.artist
                color: Colors.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: !Media.hasPlayer
                text: "No media playing"
                color: Colors.textMuted
                font.pixelSize: 13
            }

            Item { Layout.fillHeight: true } // spacer

            // Progress bar (static, not seekable)
            Rectangle {
                id: track
                Layout.fillWidth: true
                visible: Media.hasPlayer
                height: 4
                radius: 2
                color: Colors.surface

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: Colors.primary
                    width: track.width * root.progress

                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
                }
            }

            // Time + transport controls
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: Media.hasPlayer
                spacing: 6

                Text {
                    text: root.formatTime(Media.position) + " / " + root.formatTime(Media.length)
                    color: Colors.textMuted
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true } // spacer

                MediaControlButton {
                    glyph: "\u{23EE}"
                    enabled: Media.canGoPrevious
                    onClicked: Media.previous()
                }

                MediaControlButton {
                    glyph: Media.isPlaying ? "\u{23F8}" : "\u{25B6}"
                    enabled: Media.canTogglePlaying
                    big: true
                    onClicked: Media.togglePlaying()
                }

                MediaControlButton {
                    glyph: "\u{23ED}"
                    enabled: Media.canGoNext
                    onClicked: Media.next()
                }
            }
        }
    }
}
