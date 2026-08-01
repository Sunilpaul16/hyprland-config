import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

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

                // Slide-down open/close, same mechanism as DashboardPanel.qml — 0 = open, 1 = closed, driving top margin and opacity together
                property real offsetScale: root.active ? 0 : 1
                readonly property int cornerSize: 14

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
                // Stays mapped through the whole close slide, only hiding once
                // fully back behind the bar
                visible: offsetScale < 1

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

                        // Column.implicitWidth derives from its children's width, which they get back from the Column — measure the delegates directly or it deadlocks at the floor
                        readonly property real contentWidth: {
                            let w = 0;
                            for (let i = 0; i < entryRepeater.count; i++) {
                                const item = entryRepeater.itemAt(i);
                                if (item)
                                    w = Math.max(w, item.implicitWidth);
                            }
                            return w;
                        }

                        // Hangs down-right from the icon, clamped to the screen
                        x: Math.max(8, Math.min(TrayMenuState.anchorX, root.width - implicitWidth - 8))
                        // The window's own origin already sits below the bar's
                        // exclusive zone, so flush is 0 — not Config.bar.height
                        anchors.top: parent.top
                        anchors.topMargin: -(panel.height + 5) * root.offsetScale
                        implicitWidth: Math.max(160, contentWidth + 12)
                        implicitHeight: list.implicitHeight + 12
                        radius: Motion.rounding.card
                        // Top corners square so the fillets can merge them into
                        // the bar; no border, since it can't outline three sides
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
                            anchors.margins: 6
                            spacing: 2

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

                    // Concave fillets merging the panel's top corners into the bar
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
