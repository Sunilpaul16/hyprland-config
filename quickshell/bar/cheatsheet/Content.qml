import QtQuick
import "../"

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
