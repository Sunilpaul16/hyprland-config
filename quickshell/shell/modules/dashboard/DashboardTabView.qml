import QtQuick
import QtQuick.Layouts
import "../../services"

// Flickable tab content
Flickable {
    id: root

    required property var model
    property int currentIndex: 0
    required property bool heightFixed
    // Panel shown
    required property bool panelShown

    signal tabSelected(index: int)

    readonly property real paneWidth: width
    // itemAt, not children
    readonly property Item currentPane: {
        repeater.count;
        return repeater.itemAt(root.currentIndex);
    }
    property real currentPaneHeight: currentPane?.height ?? 0
    // Pane content width
    readonly property real livePaneWidth: currentPane?.item?.implicitWidth ?? 0
    // Latched width, widest pane seen
    property real currentPaneWidth: 0
    onLivePaneWidthChanged: if (livePaneWidth > 0)
        currentPaneWidth = Math.max(currentPaneWidth, livePaneWidth)

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

            // Keep adjacent alive
            delegate: Loader {
                id: paneLoader

                required property int index
                required property var modelData

                x: index * root.paneWidth
                width: root.paneWidth
                // Clip neighbours
                clip: true
                // Natural pane height
                height: root.heightFixed ? root.height : (item ? item.implicitHeight : 0)

                sourceComponent: modelData.component

                // Gated on panel
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
