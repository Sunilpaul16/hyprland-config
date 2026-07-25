import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../bar"

// Session/power overlay window — right-edge slide-in drawer
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

                // Right-edge stack registration + shared focus-grab registration
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

                // Click-through everywhere except the drawer itself
                mask: Region {
                    item: drawer
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: SessionState.open = false

                    // Hand keyboard focus to the first action button so Up/Down/Enter
                    // work immediately, without a click first
                    onFocusChanged: if (focus && loader.item) loader.item.focusFirst()

                    // Drawer: right-edge slide via animated rightMargin + opacity fade,
                    // resting/closed margins mirror SidebarRightPanel's 8px edge gap
                    Item {
                        id: drawer

                        // 0 so the drawer butts straight against the sidebar's left
                        // edge (which is itself flush at edgeMargin 0), leaving no seam
                        readonly property int restingMargin: 0
                        readonly property int cornerSize: 14
                        readonly property int closedMargin: -(drawer.implicitWidth + restingMargin)

                        // Pushed left by whichever right-edge panels are stacked
                        // outside Session (currently just Sidebar, if open)
                        property real stackOffset: RightEdgeStack.offsetFor(root.screen, "session")
                        Behavior on stackOffset {
                            NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                        }

                        // Total footprint (from the true screen edge) a panel further
                        // out needs to clear to avoid overlapping Session
                        property real registeredWidth: implicitWidth + restingMargin
                        onRegisteredWidthChanged: RightEdgeStack.register(root.screen, "session", root.active, registeredWidth)
                        Component.onCompleted: RightEdgeStack.register(root.screen, "session", root.active, registeredWidth)

                        readonly property int contentPadding: 10

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: closedMargin + (restingMargin - closedMargin) * root.showProgress + stackOffset
                        // Fallback sizing for the first open frame, before the Loader's
                        // content has laid out
                        implicitWidth: ((loader.item ? loader.item.implicitWidth : 0) || 64) + contentPadding * 2
                        implicitHeight: ((loader.item ? loader.item.implicitHeight : 0) || 384) + contentPadding * 2
                        opacity: root.showProgress

                        // Hovering holds the drawer open; leaving restarts the countdown
                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered)
                                    SessionState.cancelAutoClose();
                                else
                                    SessionState.scheduleAutoClose();
                            }
                        }

                        // Drawer backdrop — same shell as SidebarRightPanel's. Right
                        // corners are square so the joined edge reads as one surface
                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            topRightRadius: 0
                            bottomRightRadius: 0
                            color: Colors.background
                        }

                        // Concave fillets bridging the drawer into the panel beside it,
                        // rounding the two reflex corners the butt joint would leave
                        Corner {
                            anchors { right: parent.right; bottom: parent.top }
                            size: drawer.cornerSize
                            color: Colors.background
                            corner: "bottomRight"
                        }

                        Corner {
                            anchors { right: parent.right; top: parent.bottom }
                            size: drawer.cornerSize
                            color: Colors.background
                            corner: "topRight"
                        }

                        // Content only instantiated while open/animating — avoids the
                        // gif slot (and its loop animation) running while closed
                        Loader {
                            id: loader
                            anchors.centerIn: parent
                            active: root.active || root.showProgress > 0.001
                            sourceComponent: SessionContent {}
                            // Covers the case where this Loader creates its item after
                            // the focus scope's onFocusChanged already fired this tick
                            onLoaded: if (root.active) item.focusFirst()
                        }
                    }
                }
            }
        }
    }
}
