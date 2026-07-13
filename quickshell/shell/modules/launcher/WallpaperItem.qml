import QtQuick
import "../../services"


// Wallpaper list item
Item {
    id: root

    required property var modelData
    required property int index

    readonly property bool isCurrent: ListView.isCurrentItem

    width: 150
    height: ListView.view.height

    signal activated
    signal hoverActivated

    // Refresh thumbnail when ready
    Connections {
        target: Wallpapers
        function onThumbnailReady(path) {
            if (path === root.modelData.path) {
                thumb.source = "";
                thumb.source = "file://" + root.modelData.thumbPath;
            }
        }
    }

    // Thumbnail card
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

    // Hover to preview
    HoverHandler {
        onHoveredChanged: if (hovered) root.hoverActivated()
    }

    // Activate on tap
    TapHandler {
        onTapped: root.activated()
    }
}
