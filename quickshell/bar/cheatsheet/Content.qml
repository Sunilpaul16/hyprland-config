import QtQuick
import "../"

// Grouped keybind columns, end-4-style: Flow.TopToBottom with height pinned
// to the Flickable's, so a category wraps into a new column once it runs
// out of vertical room -- horizontal scroll/fade only, no per-column
// vertical scroll needed.
Item {
    id: root

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: flow.implicitWidth
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds

        Flow {
            id: flow
            height: flickable.height
            flow: Flow.TopToBottom
            spacing: 32

            Repeater {
                model: Binds.categories

                CategoryColumn {
                    required property string modelData
                    categoryName: modelData
                }
            }
        }
    }

    // Faint edge fades so a column getting cut off by the Flickable's
    // horizontal scroll reads as "more content", not a clipping glitch --
    // same idea as end-4's ScrollEdgeFade, done here as two plain gradient
    // Rectangles since that widget isn't part of this bar config.
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
