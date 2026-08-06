import QtQuick
import "../services"

// Token-driven animation
NumberAnimation {
    id: root

    // "enter" | "exit" | "spatial" | "effects" | "effectsFast"
    property string type: "spatial"

    duration: Motion.scaled(Motion.anim[root.type] ?? Motion.anim.spatial)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curve
}
