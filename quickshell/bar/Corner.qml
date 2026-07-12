import QtQuick
import QtQuick.Shapes

// Corner decorator
Item {
    id: root
    property color color: "black"
    property int size: 14

    property string corner: "topLeft"

    implicitWidth: size
    implicitHeight: size

    readonly property bool isLeft: corner === "topLeft"

    // Quarter-circle mask
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeWidth: 0

            startX: root.isLeft ? 0 : root.size
            startY: 0


            PathAngleArc {
                centerX: root.isLeft ? root.size : 0
                centerY: root.size
                radiusX: root.size
                radiusY: root.size
                startAngle: root.isLeft ? 180 : 0
                sweepAngle: root.isLeft ? 90 : -90
            }
            PathLine {
                x: root.isLeft ? 0 : root.size
                y: root.size
            }
            PathLine {
                x: root.isLeft ? 0 : root.size
                y: 0
            }
        }
    }
}
