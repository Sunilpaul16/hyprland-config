import QtQuick
import QtQuick.Shapes
import "../../../services"

// Circular usage-percentage ring (0..1). Shared by CpuCard/MemoryCard/
// BatteryCard; content (usually a percentage label) goes in as a child.
Item {
    id: root

    property real value: 0
    property color ringColor: Colors.primary
    property color trackColor: Colors.background
    property real thickness: 6

    readonly property real clampedValue: Math.max(0, Math.min(1, value))

    Behavior on value {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    Shape {
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer

        // Track (full circle)
        ShapePath {
            strokeWidth: root.thickness
            strokeColor: root.trackColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (Math.min(root.width, root.height) - root.thickness) / 2
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 359.999
            }
        }

        // Value arc
        ShapePath {
            strokeWidth: root.thickness
            strokeColor: root.ringColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (Math.min(root.width, root.height) - root.thickness) / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * root.clampedValue
            }
        }
    }
}
