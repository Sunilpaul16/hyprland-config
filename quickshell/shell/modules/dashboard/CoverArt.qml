import QtQuick
import Qt5Compat.GraphicalEffects
import "../../services"

// Rotating cover-art frame — circular mask, spins while playing
Item {
    id: root

    property real size: 140

    implicitWidth: root.size
    implicitHeight: root.size

    // Drop-shadow glow, same effect module as UserCard's avatar
    layer.enabled: true
    layer.effect: DropShadow {
        radius: 10
        samples: 21
        color: Colors.background
        opacity: 0.4
        verticalOffset: 2
    }

    // Circle-cropped art, rotates while playing
    Item {
        id: artFrame

        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: artFrame.width
                height: artFrame.height
                radius: width / 2
            }
        }

        // paused, not running: resumes its angle instead of jumping to 0
        NumberAnimation on rotation {
            running: true
            paused: !Media.isPlaying
            from: 0
            to: 360
            duration: 23500
            loops: Animation.Infinite
            easing.type: Easing.Linear
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.background
        }

        Image {
            id: art
            anchors.fill: parent
            visible: status === Image.Ready
            source: Media.artSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    // Fallback glyph — no track, or art failed to load
    Text {
        anchors.centerIn: parent
        visible: art.status === Image.Null || art.status === Image.Error
        text: "\u{266A}"
        color: Colors.textMuted
        font.pixelSize: root.size * 0.3
    }

    // Loading indicator while remote art downloads
    Text {
        anchors.centerIn: parent
        visible: art.status === Image.Loading
        text: "Loading…"
        color: Colors.textMuted
        font.pixelSize: Math.max(10, root.size * 0.08)
    }
}
