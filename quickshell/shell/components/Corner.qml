import QtQuick
import QtQuick.Shapes

// Corner decorator — quarter-circle wedge for any of the four corners
Item {
    id: root
    property color color: "black"
    property int size: 14

    // "topLeft" | "topRight" | "bottomLeft" | "bottomRight"
    property string corner: "topLeft"

    implicitWidth: size
    implicitHeight: size

    readonly property bool isTop: corner === "topLeft" || corner === "topRight"
    readonly property bool isLeft: corner === "topLeft" || corner === "bottomLeft"

    // Quarter-circle mask
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            fillColor: root.color
            strokeWidth: 0

            startX: root.isLeft ? 0 : root.size
            startY: root.isTop ? 0 : root.size

            PathAngleArc {
                moveToStart: false
                centerX: root.size - shapePath.startX
                centerY: root.size - shapePath.startY
                radiusX: root.size
                radiusY: root.size
                startAngle: {
                    if (root.corner === "topLeft")
                        return 180;
                    if (root.corner === "topRight")
                        return -90;
                    if (root.corner === "bottomLeft")
                        return 90;
                    return 0; // bottomRight
                }
                sweepAngle: 90
            }
            PathLine {
                x: shapePath.startX
                y: shapePath.startY
            }
        }
    }
}
