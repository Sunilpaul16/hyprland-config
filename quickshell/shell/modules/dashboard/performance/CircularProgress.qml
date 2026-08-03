import QtQuick
import QtQuick.Shapes
import "../../../services"

// Circular progress arc
Item {
    id: root

    property real value: 0
    property int startAngle: -90
    property int sweepAngle: 360
    property real strokeWidth: 6
    // Arc gap
    property real spacing: 4
    property color fgColor: Colors.primary
    property color bgColor: Colors.secondaryContainer
    property bool hasEndIndicator: true
    property real implicitSize: 64

    implicitWidth: root.implicitSize
    implicitHeight: root.implicitSize

    readonly property real size: Math.min(width, height)
    readonly property real arcRadius: Math.max(0, (size - strokeWidth) / 2)
    // Floored value
    property real clampedValue: Math.max(1 / 360, Math.min(1, isNaN(value) ? 0 : value))
    readonly property real gapAngle: ((spacing + strokeWidth) / (arcRadius || 1)) * (180 / Math.PI)
    readonly property bool isFullCircle: sweepAngle >= 360

    // Value end angle
    readonly property real valueEndAngle: startAngle + clampedValue * sweepAngle
    // Track end dot
    readonly property real endDotRad: (startAngle + sweepAngle - (isFullCircle ? gapAngle : 0)) * Math.PI / 180

    // Ring thickness
    readonly property real thickness: strokeWidth * 2

    Behavior on clampedValue {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    Shape {
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer

        // Remaining track
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.bgColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.valueEndAngle + root.gapAngle
                sweepAngle: Math.max(0, root.sweepAngle * (1 - root.clampedValue) - root.gapAngle * (root.isFullCircle ? 2 : 1))
            }
        }

        // Value arc
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.fgColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle
                sweepAngle: root.clampedValue * root.sweepAngle
            }
        }
    }

    // Track-end dot
    Rectangle {
        visible: root.hasEndIndicator
        width: Math.min(4, root.strokeWidth)
        height: width
        radius: width / 2
        color: root.fgColor
        x: root.size / 2 + root.arcRadius * Math.cos(root.endDotRad) - width / 2
        y: root.size / 2 + root.arcRadius * Math.sin(root.endDotRad) - height / 2
    }
}
