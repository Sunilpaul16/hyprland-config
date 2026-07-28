import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

// Tray context menu overlay window
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
                readonly property bool isOwnerScreen: ScreenOwner.owns(TrayMenuState, root.screen)
                readonly property bool active: TrayMenuState.open && root.isOwnerScreen

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
                WlrLayershell.namespace: "quickshell-tray-menu"
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
                        TrayMenuState.close();
                    }
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: TrayMenuState.close()

                    // Panel
                    Rectangle {
                        id: panel

                        x: Math.max(8, Math.min(TrayMenuState.anchorX, root.width - implicitWidth - 8))
                        // Floored at the bar's height so the menu sits flush
                        // against its underside whatever the icon's own bounds
                        y: Math.max(Config.bar.height, Math.min(TrayMenuState.anchorY, root.height - implicitHeight - 8))
                        implicitWidth: Math.max(160, list.implicitWidth + 12)
                        implicitHeight: list.implicitHeight + 12
                        radius: 12
                        color: Colors.panel
                        border.width: 1
                        border.color: Colors.outline

                        opacity: root.showProgress
                        scale: 0.96 + 0.04 * root.showProgress
                        transformOrigin: Item.TopLeft

                        // Menu entries list
                        Column {
                            id: list
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            spacing: 2

                            Repeater {
                                model: TrayMenuState.entries

                                TrayMenuItem {
                                    required property var modelData
                                    entry: modelData
                                    width: list.width
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
