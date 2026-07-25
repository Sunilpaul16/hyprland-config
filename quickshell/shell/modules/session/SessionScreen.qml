import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

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

                        readonly property int restingMargin: 8
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

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: closedMargin + (restingMargin - closedMargin) * root.showProgress + stackOffset
                        // Fallback sizing for the first open frame, before the Loader's
                        // content has laid out
                        implicitWidth: (loader.item ? loader.item.implicitWidth : 0) || 64
                        implicitHeight: (loader.item ? loader.item.implicitHeight : 0) || 384
                        opacity: root.showProgress

                        // Content only instantiated while open/animating — avoids the
                        // gif slot (and its loop animation) running while closed
                        Loader {
                            id: loader
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
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
