import QtQuick
import "../../services"
import "../../components"


// Wallpaper list item
Item {
    id: root

    required property var modelData
    required property int index

    readonly property bool isCurrent: ListView.isCurrentItem
    readonly property var view: ListView.view

    // Slot grows with the selected card so neighbours are pushed apart instead
    // of being overlapped by it
    width: root.isCurrent ? root.view.currentItemWidth : root.view.itemWidth
    height: root.view.height
    // Keeps the selected card above its neighbours mid-reflow
    z: root.isCurrent ? 1 : 0

    // The row can't clip, so items fade as they slide out of it. The fade
    // finishes well inside the panel's own padding, so nothing ever spills
    // onto the desktop
    readonly property real overflow: Math.max(root.view.contentX - root.x, (root.x + root.width) - (root.view.contentX + root.view.width))
    opacity: root.overflow <= 0 ? 1 : Math.max(0, 1 - root.overflow / 12)

    Behavior on width { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    signal activated

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

        // Fills the slot, so the row's spacing is the only gap between cards
        width: root.width
        height: root.isCurrent ? 107 : 84
        radius: Motion.rounding.item
        color: Colors.layer
        border.width: root.isCurrent ? 2 : 0
        border.color: Colors.primary

        Behavior on height { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

        Rectangle {
            id: well

            anchors.fill: parent
            anchors.margins: root.isCurrent ? 3 : 2
            radius: Motion.rounding.small
            color: Colors.background

            Image {
                id: thumb
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: "file://" + root.modelData.thumbPath
                sourceSize.width: 380
                sourceSize.height: 214
            }

            // Rounds off the image's square corners. The well's own radius can't
            // do it: a Rectangle's clip is rectangular and its border follows the
            // rounded silhouette, so neither covers the area outside the arc.
            // ClippingRectangle and layer/OpacityMask both no-op in these overlays
            Corner {
                anchors { left: parent.left; top: parent.top }
                size: well.radius
                color: card.color
                corner: "topLeft"
            }

            Corner {
                anchors { right: parent.right; top: parent.top }
                size: well.radius
                color: card.color
                corner: "topRight"
            }

            Corner {
                anchors { left: parent.left; bottom: parent.bottom }
                size: well.radius
                color: card.color
                corner: "bottomLeft"
            }

            Corner {
                anchors { right: parent.right; bottom: parent.bottom }
                size: well.radius
                color: card.color
                corner: "bottomRight"
            }
        }
    }

    // Activate on tap
    TapHandler {
        onTapped: root.activated()
    }
}
