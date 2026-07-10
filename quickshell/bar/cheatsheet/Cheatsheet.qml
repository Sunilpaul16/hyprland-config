import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"

// Keybind cheatsheet overlay. Same per-monitor/focused-monitor-only pattern
// as launcher/Launcher.qml: one instance per screen (see shell.qml), but
// only the instance on the currently focused monitor ever actually shows
// itself.
//
// Structurally this is end-4's cheatsheet (ii/modules/ii/cheatsheet/
// Cheatsheet.qml) minus everything that doesn't apply here: no tabs/pages
// (single content area — this config has no periodic-table Easter egg to
// make a second tab for), no GlobalFocusGrab/Persistent services (this bar
// has neither; click-outside + Escape, and WlrLayershell.keyboardFocus for
// grabbing input, are the same primitives launcher/Launcher.qml already
// uses to do the equivalent job).
PanelWindow {
    id: root

    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: CheatsheetState.open && root.isFocusedScreen

    // Fade in/out rather than snap, same trick as Launcher.qml's
    // showProgress: the window must stay mapped for the whole fade, so
    // `visible` is driven by showProgress, not `active` directly.
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
    WlrLayershell.namespace: "quickshell-cheatsheet"
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click-outside-to-dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: CheatsheetState.open = false
    }

    // Escape-to-dismiss. No text field to hang Keys.onEscapePressed off of
    // here (unlike launcher/Content.qml's search input), so a plain
    // focus-scoped Item takes that role instead — it only actually has
    // keyboard focus while the window holds WlrKeyboardFocus.Exclusive.
    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: CheatsheetState.open = false

        // Swallow clicks landing on the panel itself so they don't fall
        // through to the click-outside MouseArea behind it.
        MouseArea {
            anchors.fill: panel
            onClicked: {}
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: Math.round((root.screen?.width ?? 800) * 0.7)
            height: Math.round((root.screen?.height ?? 600) * 0.7)
            radius: 18
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            opacity: root.showProgress
            scale: 0.96 + 0.04 * root.showProgress
            transformOrigin: Item.Center

            Content {
                anchors.fill: parent
                anchors.margins: 28
            }
        }
    }
}
