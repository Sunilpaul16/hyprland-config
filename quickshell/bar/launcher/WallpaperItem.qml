import QtQuick
import "../"

// One carousel cell. The delegate's own Item is a fixed-size pitch slot (so
// ListView positions cells at a constant spacing); the visible card inside is
// anchored to the row's shared bottom baseline and grows + lifts above that
// baseline when it's the current item, while neighbors stay small and flush
// with the baseline — matching caelestia's PathView scale/raise effect, just
// done with plain anchors/width/height animation instead of a curved path.
// Reacts to Wallpapers' thumbnailReady signal so a video's thumbnail pops in
// once ffmpeg finishes, without the row needing to re-scan or re-query.
Item {
    id: root

    required property var modelData
    required property int index

    readonly property bool isCurrent: ListView.isCurrentItem

    // Fixed pitch: this is what ListView uses for cell spacing/positioning.
    // The card inside is allowed to visually grow past this width when
    // current — that's fine, it just overlaps into the neighbors' margin.
    width: 150
    height: ListView.view.height

    signal activated
    signal hoverActivated

    Connections {
        target: Wallpapers
        function onThumbnailReady(path) {
            if (path === root.modelData.path) {
                thumb.source = "";
                thumb.source = "file://" + root.modelData.thumbPath;
            }
        }
    }

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isCurrent ? 16 : 0

        width: root.isCurrent ? 190 : 150
        height: root.isCurrent ? 107 : 84
        radius: 10
        color: Colors.surface
        border.width: root.isCurrent ? 2 : 0
        border.color: Colors.primary

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.isCurrent ? 3 : 2
            radius: 8
            color: Colors.background
            clip: true

            Image {
                id: thumb
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: "file://" + root.modelData.thumbPath
                sourceSize.width: 380
                sourceSize.height: 214
            }
        }
    }

    HoverHandler {
        onHoveredChanged: if (hovered) root.hoverActivated()
    }

    TapHandler {
        onTapped: root.activated()
    }
}
