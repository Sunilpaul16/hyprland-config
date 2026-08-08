import QtQuick
import "../../services"
import "../../components"


// Wallpaper list item
Item {
    id: root

    required property var modelData

    readonly property var view: PathView.view
    readonly property bool isCurrent: PathView.isCurrentItem
    readonly property bool onPath: PathView.onPath

    // Slot holds shrunken tile
    implicitWidth: root.view.slotWidth
    implicitHeight: root.view.itemHeight

    // Selected draws over neighbours
    z: PathView.z ?? 0

    // Scales about its centre
    scale: 0.5
    opacity: 0

    Component.onCompleted: {
        scale = Qt.binding(() => root.isCurrent ? 1 : root.onPath ? root.view.restScale : 0);
        opacity = Qt.binding(() => root.onPath ? 1 : 0);
    }

    Behavior on scale { Anim {} }
    Behavior on opacity { Anim { type: "effects" } }

    signal activated

    // Thumbnail refresh
    Connections {
        target: Wallpapers
        function onThumbnailReady(path) {
            if (path === root.modelData.path) {
                thumb.source = "";
                thumb.source = "file://" + root.modelData.thumbPath;
            }
        }
    }

    // Thumbnail
    Rectangle {
        id: tile

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        width: root.view.tileWidth
        height: root.view.tileHeight
        radius: Motion.rounding.nested
        color: Colors.layer

        Image {
            id: thumb
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: "file://" + root.modelData.thumbPath
            sourceSize.width: root.view.tileWidth * 2
            sourceSize.height: root.view.tileHeight * 2
        }

        // Rounds image corners
        Corner {
            anchors { left: parent.left; top: parent.top }
            size: tile.radius
            color: Colors.panel
            corner: "topLeft"
        }

        Corner {
            anchors { right: parent.right; top: parent.top }
            size: tile.radius
            color: Colors.panel
            corner: "topRight"
        }

        Corner {
            anchors { left: parent.left; bottom: parent.bottom }
            size: tile.radius
            color: Colors.panel
            corner: "bottomLeft"
        }

        Corner {
            anchors { right: parent.right; bottom: parent.bottom }
            size: tile.radius
            color: Colors.panel
            corner: "bottomRight"
        }
    }

    // Name under tile
    StyledText {
        anchors.top: tile.bottom
        anchors.topMargin: Motion.spacing.tiny
        anchors.horizontalCenter: parent.horizontalCenter

        width: tile.width - Motion.spacing.large * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.modelData.label
        font.pixelSize: Motion.fontSize.body
    }

    // Activate on tap
    TapHandler {
        onTapped: root.activated()
    }
}
