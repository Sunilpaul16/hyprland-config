import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Cheatsheet overlay window
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
                readonly property bool active: CheatsheetState.open && root.isFocusedScreen

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
                WlrLayershell.namespace: "quickshell-cheatsheet"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                // Click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: CheatsheetState.open = false
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: CheatsheetState.open = false

                    // Absorb clicks on panel
                    MouseArea {
                        anchors.fill: panel
                        onClicked: {}
                    }

                    // Panel
                    Rectangle {
                        id: panel
                        anchors.centerIn: parent
                        width: Math.min(content.implicitWidth + 56, (root.screen?.width ?? 1280) * 0.9)
                        height: Math.min(content.implicitHeight + 56, (root.screen?.height ?? 800) * 0.85)
                        radius: 18
                        color: Colors.background
                        border.width: 1
                        border.color: Colors.outline

                        opacity: root.showProgress
                        scale: 0.96 + 0.04 * root.showProgress
                        transformOrigin: Item.Center

                        Content {
                            id: content
                            anchors.centerIn: parent
                            screen: root.screen
                        }
                    }
                }
            }
        }
    }
}
