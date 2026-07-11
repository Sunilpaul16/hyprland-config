import QtQuick
import QtQuick.Shapes

// A `size` x `size` square filled with `color`, with a concave lens-shaped
// bite near one corner. Two of these, colored to match the bar, sit directly
// below the bar's bottom-left/right corners — this is what makes a flush
// "hug" bar look like it curves smoothly into the content area below,
// instead of a hard 90° step.
//
// Reimplemented from scratch, same QtQuick.Shapes technique as end-4's
// RoundCorner.qml -- the arc math (which way it bulges/sweeps) is easy to
// get subtly mirrored/wrong, so this was verified empirically against a
// screenshot before being wired in.
Item {
    id: root
    property color color: "black"
    property int size: 14
    // "topLeft" or "topRight" — only the two variants our top bar needs.
    property string corner: "topLeft"

    implicitWidth: size
    implicitHeight: size

    readonly property bool isLeft: corner === "topLeft"

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeWidth: 0

            // The true screen/bar corner this shape sits at.
            startX: root.isLeft ? 0 : root.size
            startY: 0

            // Arc centered at the box corner diagonally opposite the true
            // corner, radius = size, so it passes through the two corners
            // adjacent to the true one — sweep direction mirrors for the
            // right variant since reflecting the shape reverses orientation.
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
