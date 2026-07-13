import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Session/power overlay window
PanelWindow {
    id: root

    // Visibility state
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: SessionState.open && root.isFocusedScreen

    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    // Positioning
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
    WlrLayershell.namespace: "quickshell-session"
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: SessionState.open = false
    }

    // Focus scope
    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: SessionState.open = false

        // Absorb clicks on panel
        MouseArea {
            anchors.fill: panel
            onClicked: {}
        }

        // Panel
        Rectangle {
            id: panel
            anchors.centerIn: parent
            implicitWidth: content.implicitWidth + 56
            implicitHeight: content.implicitHeight + 40
            radius: 18
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            opacity: root.showProgress
            scale: 0.96 + 0.04 * root.showProgress
            transformOrigin: Item.Center

            SessionContent {
                id: content
                anchors.centerIn: parent
                activeOverlay: root.active
            }
        }
    }
}
