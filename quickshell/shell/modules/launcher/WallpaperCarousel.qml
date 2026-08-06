import QtQuick
import "../../services"
import "../../components"

// Wallpaper carousel
Item {
    id: root

    required property var results
    required property int rowHeight
    required property int panelWidth
    required property int panelPad

    property alias currentIndex: row.currentIndex
    // Caption height
    readonly property alias captionHeight: caption.implicitHeight

    signal activated(entry: var)
    signal navigate(delta: int)

    function increment(): void {
        row.incrementCurrentIndex();
    }

    function decrement(): void {
        row.decrementCurrentIndex();
    }

    // Wallpaper carousel
    ListView {
        id: row

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.rowHeight

        // Slot widths
        readonly property int itemWidth: 150
        readonly property int currentItemWidth: 190

        orientation: ListView.Horizontal
        spacing: Motion.spacing.xlarge
        // Deliberately unclipped
        clip: false

        // Pinned centre
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - currentItemWidth) / 2
        preferredHighlightEnd: preferredHighlightBegin

        model: root.results
        onModelChanged: currentIndex = count > 0 ? 0 : -1

        highlightMoveDuration: Motion.deliberateDuration

        delegate: WallpaperItem {
            onActivated: root.activated(modelData)
        }

        // Wheel cycles selection
        WheelHandler {
            property real accumulated: 0

            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onWheel: event => {
                accumulated += event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x;
                while (accumulated >= 120) {
                    accumulated -= 120;
                    root.navigate(-1);
                }
                while (accumulated <= -120) {
                    accumulated += 120;
                    root.navigate(1);
                }
            }
        }
    }

    // Caption tracks thumbnail
    StyledText {
        id: caption
        anchors.top: row.bottom
        anchors.topMargin: Motion.spacing.tiny
        text: (row.currentIndex >= 0 && root.results[row.currentIndex]) ? root.results[row.currentIndex].label : ""
        font.pixelSize: Motion.fontSize.label
        elide: Text.ElideMiddle
        // Measured off config
        width: Math.min(implicitWidth, root.panelWidth - root.panelPad * 2)
        horizontalAlignment: Text.AlignHCenter

        x: {
            const item = row.currentItem;
            const centre = item ? item.x + item.width / 2 - row.contentX : row.width / 2;
            return Math.max(0, Math.min(row.width - width, centre - width / 2));
        }

        Behavior on x { Anim {} }
    }
}
