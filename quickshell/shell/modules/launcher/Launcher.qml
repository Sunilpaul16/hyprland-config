import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Launcher overlay window
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: PanelWindow {
                id: root
                screen: panelLoader.modelData

                // Visibility state
                readonly property bool isOwnerScreen: ScreenOwner.owns(LauncherState, root.screen)
                readonly property bool active: LauncherState.open && root.isOwnerScreen

                property real showProgress: active ? 1 : 0

                Behavior on showProgress {
                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
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
                WlrLayershell.namespace: "quickshell-launcher"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Click-through everywhere except the panel itself
                mask: Region {
                    item: content
                }

                // Shared focus-grab registration
                onActiveChanged: {
                    if (root.active)
                        GlobalFocusGrab.addDismissable(root);
                    else
                        GlobalFocusGrab.removeDismissable(root);
                }
                Connections {
                    target: GlobalFocusGrab
                    function onDismissed() {
                        LauncherState.open = false;
                    }
                }

                Content {
                    id: content
                    anchors.bottom: parent.bottom
                    // anchors.bottomMargin: 48
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.showProgress
                    scale: 0.94 + 0.06 * root.showProgress
                    transformOrigin: Item.Bottom
                }
            }
        }
    }
}
