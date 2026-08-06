import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Dismissable overlay shell
PanelWindow {
    id: root

    // Owning state singleton
    property var state: null
    property string namespace: ""
    property Item maskItem: null

    signal dismissed
    signal escapePressed

    default property alias overlayContent: focusScope.data

    // Visibility state
    readonly property bool isOwnerScreen: ScreenOwner.owns(root.state, root.screen)
    readonly property bool active: (root.state?.open ?? false) && root.isOwnerScreen

    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        Anim { type: root.active ? "enter" : "exit" }
    }

    // Positioning
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Window setup
    color: "transparent"
    exclusiveZone: 0
    visible: showProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.namespace
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Click-through mask
    mask: Region {
        item: root.maskItem
    }

    // Shared focus-grab registration
    Connections {
        target: root
        function onActiveChanged() {
            if (root.active)
                GlobalFocusGrab.addDismissable(root);
            else
                GlobalFocusGrab.removeDismissable(root);
        }
    }
    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.dismissed();
        }
    }

    // Focus scope
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.escapePressed()
    }
}
