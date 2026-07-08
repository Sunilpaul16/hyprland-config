import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"

// One instance per monitor (see shell.qml), same pattern as Bar. Only the
// instance on the currently focused monitor ever shows itself — toggling
// LauncherState.open elsewhere is a no-op for the others.
PanelWindow {
    id: root

    // `screen` is inherited from PanelWindow itself — no need to redeclare
    // it, same as Bar.qml.
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: LauncherState.open && root.isFocusedScreen

    // Animate open/close by fading+scaling the content instead of just
    // flipping `visible` — but the window itself must stay mapped for the
    // whole fade, so `visible` is driven by showProgress, not `active`
    // directly (same trick as the old pill-bar's offsetScale).
    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0
    visible: showProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    // Only grab the keyboard while actually shown, so the rest of the
    // desktop keeps working normally while the overlay is closed.
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click-outside-to-dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherState.open = false
    }

    Content {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.showProgress
        scale: 0.94 + 0.06 * root.showProgress
    }
}
