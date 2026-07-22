import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Media popup overlay window
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
                readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
                readonly property bool active: MediaState.open && root.isFocusedScreen

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
                WlrLayershell.namespace: "quickshell-media"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Click-through everywhere except the panel itself
                mask: Region {
                    item: panel
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
                        MediaState.open = false;
                    }
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: MediaState.open = false

                    // Panel
                    Rectangle {
                        id: panel

                        readonly property real restingY: Math.max(8, Math.min(MediaState.anchorY + 8, root.height - implicitHeight - 8))
                        readonly property int slideDistance: 20

                        x: Math.max(8, Math.min(MediaState.anchorX - implicitWidth / 2, root.width - implicitWidth - 8))
                        // Slides down from the bar into restingY as showProgress animates
                        y: restingY - (1 - root.showProgress) * slideDistance
                        implicitWidth: content.implicitWidth + 56
                        implicitHeight: content.implicitHeight + 40
                        radius: 18
                        color: Colors.background
                        border.width: 1
                        border.color: Colors.outline

                        opacity: root.showProgress
                        scale: 0.96 + 0.04 * root.showProgress
                        transformOrigin: Item.Top

                        MediaContent {
                            id: content
                            anchors.centerIn: parent
                        }
                    }
                }
            }
        }
    }
}
