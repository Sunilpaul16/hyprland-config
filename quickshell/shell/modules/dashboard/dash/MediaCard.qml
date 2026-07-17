import QtQuick
import QtQuick.Layouts
import "../../../services"

// Condensed media summary card — cover art, title/artist, static progress, transport controls
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

        // Cover art
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(parent.width, 140)
            Layout.preferredHeight: Layout.preferredWidth
            radius: 14
            color: Colors.background
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
                text: "\u{266A}"
                color: Colors.textMuted
                font.pixelSize: 40
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

        // Static progress bar (not seekable — see MediaTab for the draggable slider)
        Rectangle {
            id: track

            Layout.fillWidth: true
            visible: Media.hasPlayer
            implicitHeight: 4
            radius: 2
            color: Colors.background

            Rectangle {
                height: parent.height
                radius: parent.radius
                color: Colors.primary
                width: track.width * root.progress

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
            }
        }

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
