import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

// Session overlay
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
                readonly property bool isOwnerScreen: ScreenOwner.owns(SessionState, root.screen)
                readonly property bool active: SessionState.open && root.isOwnerScreen

                property real showProgress: active ? 1 : 0

                Behavior on showProgress {
                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                }

                // Stack and grab
                onActiveChanged: {
                    RightEdgeStack.register(root.screen, "session", root.active, drawer.registeredWidth);
                    if (root.active) {
                        SessionWarnings.refresh();
                        GlobalFocusGrab.addDismissable(root);
                    } else {
                        GlobalFocusGrab.removeDismissable(root);
                    }
                }
                Connections {
                    target: GlobalFocusGrab
                    function onDismissed() {
                        SessionState.open = false;
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
                visible: showProgress > 0.001

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-session"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Click-through mask
                mask: Region {
                    item: drawer
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: SessionState.open = false

                    // Focus first button
                    onFocusChanged: if (focus && loader.item) loader.item.focusFirst()

                    // Drawer
                    Item {
                        id: drawer

                        // Flush to sidebar
                        readonly property int restingMargin: 0
                        readonly property int cornerSize: 14
                        readonly property int closedMargin: -(drawer.implicitWidth + restingMargin)

                        // Stack offset
                        property real stackOffset: RightEdgeStack.offsetFor(root.screen, "session")
                        Behavior on stackOffset {
                            NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                        }

                        // Registered width
                        property real registeredWidth: implicitWidth + restingMargin
                        onRegisteredWidthChanged: RightEdgeStack.register(root.screen, "session", root.active, registeredWidth)
                        Component.onCompleted: RightEdgeStack.register(root.screen, "session", root.active, registeredWidth)

                        readonly property int contentPadding: 10

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: closedMargin + (restingMargin - closedMargin) * root.showProgress + stackOffset
                        // First-frame fallback
                        implicitWidth: ((loader.item ? loader.item.implicitWidth : 0) || 64) + contentPadding * 2
                        implicitHeight: ((loader.item ? loader.item.implicitHeight : 0) || 384) + contentPadding * 2
                        opacity: root.showProgress

                        // Hover holds open
                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered)
                                    SessionState.cancelAutoClose();
                                else
                                    SessionState.scheduleAutoClose();
                            }
                        }

                        // Backdrop
                        Rectangle {
                            anchors.fill: parent
                            radius: Motion.rounding.drawer
                            topRightRadius: 0
                            bottomRightRadius: 0
                            color: Colors.panel
                        }

                        // Edge fillets
                        Corner {
                            anchors { right: parent.right; bottom: parent.top }
                            size: drawer.cornerSize
                            color: Colors.panel
                            corner: "bottomRight"
                        }

                        Corner {
                            anchors { right: parent.right; top: parent.bottom }
                            size: drawer.cornerSize
                            color: Colors.panel
                            corner: "topRight"
                        }

                        // Lazy content
                        Loader {
                            id: loader
                            anchors.centerIn: parent
                            active: root.active || root.showProgress > 0.001
                            sourceComponent: SessionContent {}
                            // Focus after load
                            onLoaded: if (root.active) item.focusFirst()
                        }
                    }
                }
            }
        }
    }
}
