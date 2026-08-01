import QtQuick
import "../../services"

// Cheatsheet content
Item {
    id: root

    required property var screen

    readonly property int cardSpacing: 20

    // Row-count based height estimate, just for balancing columns below —
    // doesn't need to match rendered pixels exactly
    function estimatedHeight(category) {
        return 58 + Binds.rowsFor(category).length * 26;
    }

    // Column packing (longest-processing-time): sort categories tallest-first into whichever column is shortest, so more categories grow the count, not one column's height
    readonly property int columnCount: Math.max(2, Math.ceil(Binds.categories.length / 3))
    readonly property var columns: {
        const cats = [...Binds.categories].sort((a, b) => root.estimatedHeight(b) - root.estimatedHeight(a));
        const cols = Array.from({ length: root.columnCount }, () => []);
        const heights = new Array(root.columnCount).fill(0);
        for (const cat of cats) {
            let shortest = 0;
            for (let i = 1; i < heights.length; i++) {
                if (heights[i] < heights[shortest])
                    shortest = i;
            }
            cols[shortest].push(cat);
            heights[shortest] += root.estimatedHeight(cat) + root.cardSpacing;
        }
        return cols;
    }

    // Natural size read straight from the columns below — safe here, unlike a horizontal ListView's contentWidth, since Row/Column/Repeater instantiate every child
    implicitWidth: Math.min(columnsRow.implicitWidth, (root.screen?.width ?? 1280) * 0.85)
    implicitHeight: Math.min(columnsRow.implicitHeight, (root.screen?.height ?? 800) * 0.8)
    width: implicitWidth
    height: implicitHeight

    // Scrollable column row
    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: columnsRow.implicitWidth
        contentHeight: Math.max(height, columnsRow.implicitHeight)
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: columnsRow
            spacing: root.cardSpacing

            Repeater {
                model: root.columns

                Column {
                    id: columnItem
                    required property var modelData
                    spacing: root.cardSpacing

                    Repeater {
                        model: columnItem.modelData

                        CategoryColumn {
                            required property string modelData
                            categoryName: modelData
                        }
                    }
                }
            }
        }
    }

    // Left scroll fade
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 24
        visible: flickable.contentX > 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Colors.background }
            GradientStop { position: 1; color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0) }
        }
    }
    // Right scroll fade
    Rectangle {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 24
        visible: flickable.contentX < flickable.contentWidth - flickable.width - 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0) }
            GradientStop { position: 1; color: Colors.background }
        }
    }
}
