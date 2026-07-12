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
            id: shapePath
            fillColor: root.color
            strokeWidth: 0

            startX: root.isLeft ? 0 : root.size
            startY: 0

            // moveToStart:false + matching startAngle per corner (mirrors
            // end-4/dots-hyprland's RoundCorner.qml) is required here —
            // without it the default moveToStart:true jump plus a second
            // redundant PathLine produced a self-intersecting crescent
            // instead of a clean wedge, most visible on the right corner.
            PathAngleArc {
                moveToStart: false
                centerX: root.isLeft ? root.size : 0
                centerY: root.size
                radiusX: root.size
                radiusY: root.size
                startAngle: root.isLeft ? 180 : -90
                sweepAngle: 90
            }
            PathLine {
                x: shapePath.startX
                y: shapePath.startY
            }
        }
    }
}
