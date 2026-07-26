import QtQuick
import QtQuick.Shapes
import "../../../services"

// Scalloped blob behind a hero card's usage percentage. Stands in for
// caelestia's MaterialShape (Cookie4Sided / Sunny / SoftBurst), which comes
// from its M3Shapes C++ plugin — this repo has no plugin, so the same shape
// family is sampled in polar form instead: more lobes and a tighter waist as
// usage climbs, matching the shape swap caelestia does at 40% and 80%.
Item {
    id: root

    property real value: 0
    property color color: Colors.secondaryContainer
    property real implicitSize: 76

    implicitWidth: root.implicitSize
    implicitHeight: root.implicitSize

    readonly property real clampedValue: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    // Lobe count / depth step at the same thresholds caelestia switches shape on
    readonly property int lobes: root.clampedValue >= 0.8 ? 12 : (root.clampedValue >= 0.4 ? 8 : 4)
    readonly property real depth: root.clampedValue >= 0.8 ? 0.12 : (root.clampedValue >= 0.4 ? 0.14 : 0.18)

    // Polar outline: r(t) dips by `depth` between lobes, sampled densely
    // enough that a polyline reads as a smooth curve. The half-lobe phase
    // offset puts the widest points on the diagonals, so a 4-lobe blob reads
    // as a rounded square like M3's Cookie4Sided rather than as a diamond
    readonly property var outline: {
        const cx = width / 2;
        const cy = height / 2;
        const r = Math.min(width, height) / 2;
        const steps = 180;
        const phase = Math.PI / root.lobes;
        const pts = [];
        for (let i = 0; i <= steps; i++) {
            const t = (i / steps) * Math.PI * 2;
            const rr = r * (1 - root.depth * (1 - Math.cos(root.lobes * (t + phase))) / 2);
            pts.push(Qt.point(cx + rr * Math.cos(t), cy + rr * Math.sin(t)));
        }
        return pts;
    }

    Shape {
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color

            PathPolyline {
                path: root.outline
            }
        }
    }
}
