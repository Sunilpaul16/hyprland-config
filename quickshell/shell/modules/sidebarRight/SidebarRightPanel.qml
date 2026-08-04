import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

// Right sidebar overlay
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

                // Edge stack registration
                readonly property int cornerSize: Motion.cornerSize
                readonly property real registeredWidth: backdrop.width

                onActiveChanged: {
                    RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth);
                    if (!root.active) {
                        SidebarDialogState.close();
                        GlobalFocusGrab.removeDismissable(root);
                    } else {
                        GlobalFocusGrab.addDismissable(root);
                    }
                }
                onRegisteredWidthChanged: RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth)
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

                // Click-through mask
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

                    // Backdrop
                    Rectangle {
                        id: backdrop
                        anchors { top: parent.top; right: parent.right }
                        width: Config.sidebar.width
                        height: parent.height
                        // Square left corners
                        topLeftRadius: 0
                        bottomLeftRadius: 0
                        // Square right corners
                        topRightRadius: 0
                        bottomRightRadius: 0
                        color: Colors.panel
                        opacity: root.showProgress
                        transform: Translate { x: (1 - root.showProgress) * 24 }
                    }

                    // Edge fillets
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

                    // Slide-in wrapper
                    Item {
                        anchors.fill: backdrop
                        visible: SidebarDialogState.openDialog === ""

                        opacity: root.showProgress
                        transform: Translate { x: (1 - root.showProgress) * 24 }

                        // Card stack
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Motion.spacing.large

                            spacing: Motion.spacing.large

                            SystemHeaderCard { Layout.fillWidth: true }
                            QuickTogglesCard { Layout.fillWidth: true }
                            KeepAwakeCard { Layout.fillWidth: true; visible: KeepAwakeCardState.enabled }
                            ScreenRecorderCard { Layout.fillWidth: true; visible: ScreenRecorderCardState.enabled }

                            // Divider
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: Motion.spacing.tiny
                                Layout.bottomMargin: Motion.spacing.tiny
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

                    // Toggle dialogs
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
