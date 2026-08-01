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
    // itemAt(), not children[] — these Loaders' async `active` toggling reorders paneRow.children; repeater.count forces re-evaluation, since itemAt() alone isn't tracked
    readonly property Item currentPane: {
        repeater.count;
        return repeater.itemAt(root.currentIndex);
    }
    property real currentPaneHeight: currentPane?.height ?? 0
    // Read off the pane's own content, never paneWidth — the panel's auto width feeds this, so anything derived from root.width deadlocks at 0
    readonly property real livePaneWidth: currentPane?.item?.implicitWidth ?? 0
    // Latched to the last real width — the pane is destroyed while closed, and dropping to the floor snaps the panel narrower mid close-animation
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

            // Keeps whichever adjacent tab is mid-scroll during a drag instantiated too, not just the current one
            delegate: Loader {
                id: paneLoader

                required property int index
                required property var modelData

                x: index * root.paneWidth
                width: root.paneWidth
                // The panel sizes to the *current* pane, so a wider one (Media) would paint over its neighbour's slot while a narrower tab shows
                clip: true
                // Own natural content height, not the tallest tab's, so currentPaneHeight follows the current pane and animates on switch
                // Fixed-height mode flips this: pane fills the view's height instead
                height: root.heightFixed ? root.height : (item ? item.implicitHeight : 0)

                sourceComponent: modelData.component

                // Gate on the panel being shown, not just index === currentIndex — otherwise the default tab's loader stays active from construction on every monitor, polling 24/7
                // panelShown loads eagerly on open and retains content through the close fade-out
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
