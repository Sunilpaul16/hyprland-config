import QtQuick
import "../../services"
import "../../components"

// Wallpaper mode: horizontal thumbnail carousel plus its caption — selection movement is exposed, not driven here, so the launcher can pair each move with its debounced --preview
Item {
    id: root

    required property var results
    required property int rowHeight
    required property int panelWidth
    required property int panelPad

    property alias currentIndex: row.currentIndex
    // Read by the launcher to size the panel in wallpaper mode
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

        // Slot widths, read back by the delegate
        readonly property int itemWidth: 150
        readonly property int currentItemWidth: 190

        orientation: ListView.Horizontal
        spacing: 16
        // Deliberately unclipped — a Shape renders nothing under a clipping ancestor, and the delegates round corners with one; they fade at the row's edges instead
        clip: false

        // Begin == end pins the selection dead centre — a range with width lets it drift anywhere inside
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - currentItemWidth) / 2
        preferredHighlightEnd: preferredHighlightBegin

        model: root.results
        onModelChanged: currentIndex = count > 0 ? 0 : -1

        highlightMoveDuration: Motion.deliberateDuration

        delegate: WallpaperItem {
            onActivated: root.activated(modelData)
        }

        // Wheel cycles the selection, accumulating deltas to a full notch so a trackpad steps at the same rate as a mouse wheel
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

    // Caption tracks the selected thumbnail, not the panel centre, so the name reads as belonging to it
    StyledText {
        id: caption
        anchors.top: row.bottom
        anchors.topMargin: 4
        text: (row.currentIndex >= 0 && root.results[row.currentIndex]) ? root.results[row.currentIndex].label : ""
        font.pixelSize: Motion.fontSize.label
        elide: Text.ElideMiddle
        // Measured against the panel constant, never the parent it
        // sits in — see the polish-loop note in CLAUDE.md
        width: Math.min(implicitWidth, root.panelWidth - root.panelPad * 2)
        horizontalAlignment: Text.AlignHCenter

        x: {
            const item = row.currentItem;
            const centre = item ? item.x + item.width / 2 - row.contentX : row.width / 2;
            return Math.max(0, Math.min(row.width - width, centre - width / 2));
        }

        Behavior on x { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
    }
}
