import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// Right sidebar overlay
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: OverlayWindow {
                id: root
                screen: panelLoader.modelData
                state: SidebarRightState
                namespace: "quickshell-sidebar-right"
                maskItem: backdrop

                onDismissed: SidebarRightState.open = false
                onEscapePressed: {
                    if (SidebarDialogState.openDialog !== "" || SidebarDialogState.mixerOpen)
                        SidebarDialogState.close();
                    else
                        SidebarRightState.open = false;
                }

                // Edge stack registration
                readonly property int cornerSize: Motion.cornerSize
                readonly property bool portrait: (root.screen?.height ?? 0) > (root.screen?.width ?? 0)
                readonly property real registeredWidth: backdrop.width

                onActiveChanged: {
                    RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth);
                    if (!root.active)
                        SidebarDialogState.close();
                }
                onRegisteredWidthChanged: RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth)
                Component.onCompleted: RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth)

                // Backdrop
                Rectangle {
                    id: backdrop
                    anchors { top: parent.top; right: parent.right }
                    width: Math.min(root.portrait ? Math.max(Config.sidebar.width, Math.round(parent.width * 0.29)) : Config.sidebar.width,
                        Math.max(1, parent.width - root.cornerSize))
                    height: parent.height
                    // Square left corners
                    topLeftRadius: 0
                    bottomLeftRadius: 0
                    // Square right corners
                    topRightRadius: 0
                    bottomRightRadius: 0
                    color: Colors.panel
                    opacity: root.showProgress
                    transform: Translate { x: (1 - root.showProgress) * backdrop.width }
                }

                // Edge fillets
                Corner {
                    anchors { right: backdrop.left; top: backdrop.top }
                    size: root.cornerSize
                    color: Colors.panel
                    corner: "topRight"
                    opacity: root.showProgress
                    transform: Translate { x: (1 - root.showProgress) * backdrop.width }
                }

                Corner {
                    anchors { right: backdrop.left; bottom: backdrop.bottom }
                    size: root.cornerSize
                    color: Colors.panel
                    corner: "bottomRight"
                    opacity: root.showProgress
                    transform: Translate { x: (1 - root.showProgress) * backdrop.width }
                }

                // Slide-in wrapper
                Item {
                    anchors.fill: backdrop
                    visible: SidebarDialogState.openDialog === ""

                    opacity: root.showProgress
                    transform: Translate { x: (1 - root.showProgress) * backdrop.width }

                    // Card stack
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Motion.spacing.large

                        spacing: Motion.spacing.large

                        SystemHeaderCard { Layout.fillWidth: true }
                        QuickTogglesCard { Layout.fillWidth: true }
                        VolumeMixerCard { Layout.fillWidth: true }
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
            }
        }
    }
}
