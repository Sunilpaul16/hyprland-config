import QtQuick
import "../../services"
import "../../components"

// Wallpaper carousel
Item {
    id: root

    required property var results
    required property int availableWidth

    // Tile geometry
    readonly property int tileWidth: 280
    readonly property int tileHeight: Math.round(root.tileWidth / 16 * 9)
    readonly property real restScale: 0.8
    readonly property int slotWidth: Math.round(root.tileWidth * root.restScale) + Motion.spacing.large * 2
    readonly property int itemHeight: root.tileHeight + Motion.spacing.tiny + labelMetrics.implicitHeight

    // Odd slot count fits width
    readonly property int slotCount: {
        const fits = Math.floor(root.availableWidth / root.slotWidth);
        const visible = Math.min(fits, root.results.length);
        if (visible < 1)
            return 0;
        if (visible === 2)
            return 1;
        return visible % 2 === 0 ? visible - 1 : visible;
    }

    property alias currentIndex: view.currentIndex

    implicitWidth: root.slotCount * root.slotWidth
    implicitHeight: root.itemHeight

    signal activated(entry: var)
    signal navigate(delta: int)

    function increment(): void {
        view.incrementCurrentIndex();
    }

    function decrement(): void {
        view.decrementCurrentIndex();
    }

    // Label height probe
    StyledText {
        id: labelMetrics
        visible: false
        text: "Ag"
        font.pixelSize: Motion.fontSize.body
    }

    // Wallpaper carousel
    PathView {
        id: view

        anchors.fill: parent

        // Read by delegates
        readonly property int tileWidth: root.tileWidth
        readonly property int tileHeight: root.tileHeight
        readonly property int slotWidth: root.slotWidth
        readonly property int itemHeight: root.itemHeight
        readonly property real restScale: root.restScale

        model: root.results
        onModelChanged: if (count > 0) currentIndex = 0

        pathItemCount: Math.max(1, root.slotCount)
        cacheItemCount: 4

        // Pinned centre
        snapMode: PathView.SnapToItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightMoveDuration: Motion.scaled(Motion.anim.spatial)

        delegate: WallpaperItem {
            onActivated: root.activated(modelData)
        }

        // Straight row, centre on top
        path: Path {
            startY: view.height / 2

            PathAttribute {
                name: "z"
                value: 0
            }
            PathLine {
                x: view.width / 2
                relativeY: 0
            }
            PathAttribute {
                name: "z"
                value: 1
            }
            PathLine {
                x: view.width
                relativeY: 0
            }
            PathAttribute {
                name: "z"
                value: 0
            }
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
}
