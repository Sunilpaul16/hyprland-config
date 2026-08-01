import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

// Right sidebar overlay window
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
                readonly property bool isOwnerScreen: ScreenOwner.owns(SidebarRightState, root.screen)
                readonly property bool active: SidebarRightState.open && root.isOwnerScreen

                property real showProgress: active ? 1 : 0

                Behavior on showProgress {
                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                }

                // Right-edge stack registration — always flush to the edge itself, but other panels need its open+width to offset past it
                readonly property int edgeMargin: 0
                readonly property int cornerSize: 14
                readonly property real registeredWidth: backdrop.width + edgeMargin

                onActiveChanged: {
                    RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth);
                    if (!root.active) {
                        SidebarDialogState.close();
                        GlobalFocusGrab.removeDismissable(root);
                    } else {
                        GlobalFocusGrab.addDismissable(root);
                    }
                }
                Component.onCompleted: RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth)
                Connections {
                    target: GlobalFocusGrab
                    function onDismissed() {
                        SidebarRightState.open = false;
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
                exclusiveZone: 0
                color: "transparent"
                visible: showProgress > 0.001

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-sidebar-right"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Click-through everywhere except the sidebar itself
                mask: Region {
                    item: backdrop
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: {
                        if (SidebarDialogState.openDialog !== "")
                            SidebarDialogState.close();
                        else
                            SidebarRightState.open = false;
                    }

                    // Sidebar backdrop — full monitor height so NotificationsCard absorbs the leftover space
                    Rectangle {
                        id: backdrop
                        anchors { top: parent.top; right: parent.right; margins: root.edgeMargin }
                        width: 360
                        height: parent.height - root.edgeMargin * 2
                        radius: 20
                        // Left corners square so the fillets below can flare this edge
                        // out into the bar above and the screen bottom
                        topLeftRadius: 0
                        bottomLeftRadius: 0
                        // Right corners too — they butt the screen edge, and the bar's concave fillet above must meet flush or a crescent of wallpaper shows through
                        topRightRadius: 0
                        bottomRightRadius: 0
                        color: Colors.panel
                        opacity: root.showProgress
                        transform: Translate { x: (1 - root.showProgress) * 24 }
                    }

                    // Concave fillets flaring the sidebar's left edge into the bar
                    // above and the screen bottom, same treatment as the session drawer
                    Corner {
                        anchors { right: backdrop.left; top: backdrop.top }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "topRight"
                        opacity: root.showProgress
                        transform: Translate { x: (1 - root.showProgress) * 24 }
                    }

                    Corner {
                        anchors { right: backdrop.left; bottom: backdrop.bottom }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "bottomRight"
                        opacity: root.showProgress
                        transform: Translate { x: (1 - root.showProgress) * 24 }
                    }

                    // Slide-in wrapper — the animation lives here, not on the ColumnLayout, so qmllint stops reading the Translate's x as layout-managed geometry
                    Item {
                        anchors.fill: backdrop
                        visible: SidebarDialogState.openDialog === ""

                        opacity: root.showProgress
                        transform: Translate { x: (1 - root.showProgress) * 24 }

                        // Card stack, no outer Flickable — the notifications card fills the slack and scrolls internally, so the cards below stay pinned to the bottom
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            spacing: 12

                            SystemHeaderCard { Layout.fillWidth: true }
                            QuickTogglesCard { Layout.fillWidth: true }
                            KeepAwakeCard { Layout.fillWidth: true; visible: KeepAwakeCardState.enabled }
                            ScreenRecorderCard { Layout.fillWidth: true; visible: ScreenRecorderCardState.enabled }

                            // Separates the utility cards from the notifications region
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                Layout.bottomMargin: 4
                                implicitHeight: 1
                                color: Colors.outline
                                opacity: 0.35
                            }

                            NotificationsCard {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 120
                            }

                            CalendarCard {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: implicitHeight
                            }
                        }
                    }

                    // In-panel toggle dialogs, same overlay area (comparison.md #25)
                    ToggleDialog {
                        anchors.fill: backdrop
                        shown: SidebarDialogState.openDialog === "bluetooth"
                        sourceComponent: BluetoothDialog {}
                    }

                    ToggleDialog {
                        anchors.fill: backdrop
                        shown: SidebarDialogState.openDialog === "volume"
                        sourceComponent: VolumeMixerDialog {}
                    }
                }
            }
        }
    }
}
