import QtQuick
import QtQuick.Shapes
import "../../services"

// Seek slider
Item {
    id: root

    property real value: 0         // 0..1
    property bool animate: false  // travel the wave
    property real waveFrequency: 5  // full-width cycle
    property int waveDuration: 2000
    property real waveThickness: 5
    property real amplitude: 4
    property real trackThickness: 4

    readonly property real handleWidth: 4
    readonly property real gap: 6
    readonly property real dotSize: 4

    readonly property bool dragging: mouse.pressed
    readonly property real displayValue: Math.max(0, Math.min(1, root.dragging ? root.dragValue : root.value))
    readonly property real waveWidth: Math.max(0, root.handleX - root.gap)
    readonly property real wavelength: root.waveFrequency > 0 ? root.width / root.waveFrequency : root.width

    // Smoothed handle position
    property real handleX: root.displayValue * (root.width - root.handleWidth)
    property real dragValue: 0
    property real phase: 0

    signal seeked(real position)

    implicitWidth: 200
    implicitHeight: 20
    opacity: root.enabled ? 1 : 0.38

    Behavior on handleX {
        enabled: !root.dragging
        NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
    }

    // Sine samples
    function wavePoints(): var {
        const w = root.waveWidth;
        const cy = wave.height / 2;
        if (w <= 0 || root.wavelength <= 0)
            return [];

        const pts = [];
        for (let x = 0; x <= w; x += 2)
            pts.push(Qt.point(x, cy + root.amplitude * Math.sin(x / root.wavelength * 2 * Math.PI - root.phase)));
        if (pts[pts.length - 1].x < w)
            pts.push(Qt.point(w, cy + root.amplitude * Math.sin(w / root.wavelength * 2 * Math.PI - root.phase)));
        return pts;
    }

    NumberAnimation on phase {
        running: !Motion.reduced
        paused: !root.animate
        from: 0
        to: 2 * Math.PI
        duration: Motion.scaled(root.waveDuration)
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    // Played portion
    Shape {
        id: wave

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.waveWidth
        height: root.amplitude * 2 + root.waveThickness
        visible: root.waveWidth > 0
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.waveThickness
            strokeColor: Colors.primary
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline { path: root.wavePoints() }
        }
    }

    Rectangle {
        id: handle

        x: root.handleX
        anchors.verticalCenter: parent.verticalCenter
        width: root.handleWidth
        height: root.dragging ? parent.height : parent.height * 0.8
        radius: width / 2
        color: Colors.primary

        Behavior on height { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    // Remaining track
    Rectangle {
        id: remaining

        x: handle.x + root.handleWidth + root.gap
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.width - root.dotSize - root.gap - remaining.x)
        height: root.trackThickness
        radius: height / 2
        color: Colors.secondaryContainer
    }

    // Stop indicator
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        width: root.dotSize
        height: root.dotSize
        radius: width / 2
        color: Colors.primary
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        onPressed: e => root.dragValue = Math.max(0, Math.min(1, e.x / width))
        onPositionChanged: e => {
            if (mouse.pressed)
                root.dragValue = Math.max(0, Math.min(1, e.x / width));
        }
        onReleased: root.seeked(root.dragValue)
    }
}
