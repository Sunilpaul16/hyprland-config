import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

// Tray menu overlay
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

                // Slide-down open
                property real offsetScale: root.active ? 0 : 1
                readonly property int cornerSize: Motion.cornerSize

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Motion.animationCurves.expressiveDefaultSpatialDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.animationCurves.expressiveDefaultSpatial
                    }
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
                // Mapped while sliding
                visible: offsetScale < 1

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-tray-menu"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Click-through mask
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

                        // Measure delegates directly
                        readonly property real contentWidth: {
                            let w = 0;
                            for (let i = 0; i < entryRepeater.count; i++) {
                                const item = entryRepeater.itemAt(i);
                                if (item)
                                    w = Math.max(w, item.implicitWidth);
                            }
                            return w;
                        }

                        // Anchored to icon
                        x: Math.max(8, Math.min(TrayMenuState.anchorX, root.width - implicitWidth - 8))
                        // Flush below bar
                        anchors.top: parent.top
                        anchors.topMargin: -(panel.height + 5) * root.offsetScale
                        implicitWidth: Math.max(160, contentWidth + 12)
                        implicitHeight: list.implicitHeight + 12
                        radius: Motion.rounding.card
                        // Square top corners
                        topLeftRadius: 0
                        topRightRadius: 0
                        color: Colors.panel

                        opacity: 1 - root.offsetScale

                        // Menu entries list
                        Column {
                            id: list
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: Motion.spacing.small
                            spacing: Motion.spacing.micro

                            Repeater {
                                id: entryRepeater
                                model: TrayMenuState.entries

                                TrayMenuItem {
                                    required property var modelData
                                    entry: modelData
                                    width: list.width
                                }
                            }
                        }
                    }

                    // Bar fillets
                    Corner {
                        anchors { right: panel.left; top: panel.top }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "topRight"
                        opacity: panel.opacity
                    }

                    Corner {
                        anchors { left: panel.right; top: panel.top }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "topLeft"
                        opacity: panel.opacity
                    }
                }
            }
        }
    }
}
