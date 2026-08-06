import QtQuick
import "../services"

// Colour cross-fade
ColorAnimation {
    duration: Motion.scaled(Motion.anim.effects)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curve
}
