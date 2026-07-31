import QtQuick
import QtQuick.Layouts
import "../../services"

// Horizontally-flickable tab content (one pane per tab, swipeable).
// Drag-commit raises the new index rather than writing it — the panel owns currentTab
Flickable {
    id: root

    required property var model
    property int currentIndex: 0
    required property bool heightFixed
    // The panel's own shown state, not this item's visibility — see the
    // Loader gating below
    required property bool panelShown

    signal tabSelected(index: int)

    readonly property real paneWidth: width
    // itemAt(), not children[] — unlike the tab bar's plain Rectangle
    // delegates, these Loaders' async `active` toggling reorders
    // paneRow.children, so position-based indexing is unreliable here.
    // repeater.count is read only to force re-evaluation once the
    // Repeater finishes populating (itemAt() alone isn't tracked)
    readonly property Item currentPane: {
        repeater.count;
        return repeater.itemAt(root.currentIndex);
    }
    property real currentPaneHeight: currentPane?.height ?? 0
    // Read off the pane's own content, never off paneWidth — the
    // panel's auto width feeds this, so anything derived from
    // root.width here would deadlock at 0
    readonly property real livePaneWidth: currentPane?.item?.implicitWidth ?? 0
    // Latched to the last real width: the pane is destroyed while the
    // dashboard is closed, and letting that drop the panel to its floor
    // snaps it narrower mid close-animation
    property real currentPaneWidth: 0
    onLivePaneWidthChanged: if (livePaneWidth > 0)
        currentPaneWidth = livePaneWidth

    Layout.fillWidth: true
    Layout.fillHeight: root.heightFixed
    Layout.preferredHeight: root.heightFixed ? -1 : currentPaneHeight

    Behavior on currentPaneHeight {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    flickableDirection: Flickable.HorizontalFlick
    contentWidth: paneRow.width
    contentHeight: height
    contentX: root.currentIndex * paneWidth
    clip: true

    Behavior on contentX {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    onDragEnded: {
        const delta = contentX - root.currentIndex * paneWidth;
        if (delta > paneWidth / 10)
            root.tabSelected(Math.min(root.currentIndex + 1, root.model.length - 1));
        else if (delta < -paneWidth / 10)
            root.tabSelected(Math.max(root.currentIndex - 1, 0));
        contentX = Qt.binding(() => root.currentIndex * root.paneWidth);
    }

    Item {
        id: paneRow
        width: root.model.length * root.paneWidth
        height: root.height

        Repeater {
            id: repeater

            model: root.model

            // Also keeps whichever adjacent tab is mid-scroll
            // during a drag instantiated, not just the current
            // tab
            delegate: Loader {
                id: paneLoader

                required property int index
                required property var modelData

                x: index * root.paneWidth
                width: root.paneWidth
                // The panel sizes to the *current* pane, so a wider pane
                // (Media) would otherwise paint over its neighbour's slot
                // whenever a narrower tab is showing
                clip: true
                // Own natural content height, not the tallest tab's —
                // root.currentPaneHeight then follows whichever pane
                // is current, animated on switch
                // Fixed-height mode flips this: pane fills the view's height instead
                height: root.heightFixed ? root.height : (item ? item.implicitHeight : 0)

                sourceComponent: modelData.component

                // Gate on the panel actually being shown, not just
                // index === currentIndex: the default tab's loader
                // would otherwise stay active from window construction
                // (on every monitor, dashboard closed or not), keeping
                // its cards' services polling 24/7 and defeating the
                // ref-counted "only poll while referenced" design.
                // panelShown loads eagerly on open and retains
                // content through the close fade-out.
                Component.onCompleted: active = Qt.binding(() => {
                    if (!root.panelShown)
                        return false;
                    if (index === root.currentIndex)
                        return true;
                    const vx = Math.floor(root.visibleArea.xPosition * root.contentWidth);
                    const vex = Math.floor(vx + root.visibleArea.widthRatio * root.contentWidth);
                    return (vx >= x && vx <= x + width) || (vex >= x && vex <= x + width);
                })
            }
        }
    }
}
