import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../services"

// Media tab: full-page now-playing — cover art, draggable seek, transport controls
Item {
    id: root

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
        anchors.centerIn: parent
        visible: Media.hasPlayer
        spacing: 32

        // Cover art
        Rectangle {
            Layout.preferredWidth: 260
            Layout.preferredHeight: 260
            radius: 20
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
                text: "\u{266A}"
                color: Colors.textMuted
                font.pixelSize: 72
            }
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
                    color: Colors.surface

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
                    radius: 7
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
                spacing: 28

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
            font.pixelSize: btn.big ? 26 : 18

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
