import QtQuick
import Qt5Compat.GraphicalEffects
import "../../services"
import "../../components"

// Cover art frame
Item {
    id: root

    property real size: 140

    implicitWidth: root.size
    implicitHeight: root.size

    // Pending remote art
    readonly property bool artPending: Media.artIsRemote && !Media.artDownloaded && Media.artUrl.length > 0

    // Glow
    layer.enabled: true
    layer.effect: DropShadow {
        radius: Motion.rounding.item
        samples: 21
        color: Colors.background
        opacity: 0.4
        verticalOffset: 2
    }

    // Circle-cropped art
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

        // Backing disc
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

    // Fallback glyph
    StyledText {
        anchors.centerIn: parent
        visible: (art.status === Image.Null || art.status === Image.Error) && !root.artPending
        text: "\u{266A}"
        color: Colors.textMuted
        font.pixelSize: root.size * 0.3
    }

    // Loading indicator
    StyledText {
        anchors.centerIn: parent
        visible: art.status === Image.Loading || root.artPending
        text: "Loading…"
        color: Colors.textMuted
        font.pixelSize: Math.max(10, root.size * 0.08)
    }
}
