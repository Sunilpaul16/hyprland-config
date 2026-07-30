import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../../components"

// Volume/mic OSD window — right-edge slide-in drawer, auto-show-on-change
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

                property bool triggered: false
                readonly property bool active: root.triggered && root.isFocusedScreen

                property bool startupGraceOver: false
                // Startup grace period — suppresses the spurious trigger every
                // Audio.qml property emits on shell launch
                Timer {
                    interval: 1000
                    running: true
                    onTriggered: root.startupGraceOver = true
                }

                property real showProgress: active ? 1 : 0
                Behavior on showProgress {
                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                }

                // Right-edge stack registration
                onActiveChanged: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, drawer.registeredWidth)

                // Show (and restart the auto-hide timer) on any sink/source change
                function show(): void {
                    if (!root.startupGraceOver || !Config.audio.osdEnabled)
                        return;
                    root.triggered = true;
                    armHideTimer();
                }

                // Keeps the timer stopped while hovered instead of letting a
                // scroll-triggered restart race past a still-active hover
                function armHideTimer(): void {
                    if (drawer.hovered)
                        hideTimer.stop();
                    else
                        hideTimer.restart();
                }

                Connections {
                    target: Audio
                    function onVolumeChanged() { root.show(); }
                    function onMutedChanged() { root.show(); }
                    function onSourceVolumeChanged() { root.show(); }
                    function onMicMutedChanged() { root.show(); }
                }

                // Auto-hide timer
                Timer {
                    id: hideTimer
                    interval: Config.audio.osdTimeout
                    onTriggered: root.triggered = false
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
                visible: Config.audio.osdEnabled && showProgress > 0.001

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-volume-osd"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                // Click/scroll-through everywhere except the drawer itself — this is
                // a passive toast, not a modal, so no click-outside-to-close
                mask: Region {
                    item: drawer
                }

                // Drawer: right-edge slide via animated rightMargin + opacity fade,
                // same mechanism as SessionScreen
                Item {
                    id: drawer

                    property bool hovered: false

                    // 0 so the drawer sits flush against the screen edge and the
                    // fillets below have a straight edge to bridge into, matching
                    // SessionScreen
                    readonly property int restingMargin: 0
                    readonly property int cornerSize: 14
                    readonly property int contentPadding: 10
                    readonly property int closedMargin: -(drawer.implicitWidth + restingMargin)

                    // Which edge the drawer hugs
                    readonly property bool onRight: Config.audio.osdEdge !== "left"

                    // Pushed left by whichever right-edge panels are stacked outside
                    // this one (Sidebar and/or Session, if open). Left-edge has no
                    // stackmates, so it never offsets
                    property real stackOffset: RightEdgeStack.offsetFor(root.screen, "volume")
                    Behavior on stackOffset {
                        NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                    }

                    property real registeredWidth: implicitWidth + restingMargin
                    onRegisteredWidthChanged: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, registeredWidth)
                    onOnRightChanged: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, registeredWidth)
                    Component.onCompleted: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, registeredWidth)

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: drawer.onRight ? parent.right : undefined
                    anchors.left: drawer.onRight ? undefined : parent.left
                    anchors.rightMargin: drawer.onRight ? (closedMargin + (restingMargin - closedMargin) * root.showProgress + stackOffset) : 0
                    anchors.leftMargin: drawer.onRight ? 0 : (closedMargin + (restingMargin - closedMargin) * root.showProgress)
                    // Fallback sizing for the first open frame, before the Loader's
                    // content has laid out (same race SessionScreen's drawer guards)
                    implicitWidth: ((loader.item ? loader.item.implicitWidth : 0) || 24) + contentPadding * 2
                    implicitHeight: ((loader.item ? loader.item.implicitHeight : 0) || 296) + contentPadding * 2
                    opacity: root.showProgress

                    HoverHandler {
                        onHoveredChanged: {
                            drawer.hovered = hovered;
                            if (!hovered)
                                root.armHideTimer();
                            else
                                hideTimer.stop();
                        }
                    }

                    // Drawer backdrop — same shell as SessionScreen's. The corners
                    // on the hugged edge are square so the joint reads as one surface
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        topRightRadius: drawer.onRight ? 0 : 20
                        bottomRightRadius: drawer.onRight ? 0 : 20
                        topLeftRadius: drawer.onRight ? 20 : 0
                        bottomLeftRadius: drawer.onRight ? 20 : 0
                        color: Colors.panel
                    }

                    // Concave fillets bridging the drawer into the screen edge,
                    // rounding the two reflex corners the butt joint would leave
                    Corner {
                        anchors {
                            right: drawer.onRight ? parent.right : undefined
                            left: drawer.onRight ? undefined : parent.left
                            bottom: parent.top
                        }
                        size: drawer.cornerSize
                        color: Colors.panel
                        corner: drawer.onRight ? "bottomRight" : "bottomLeft"
                    }

                    Corner {
                        anchors {
                            right: drawer.onRight ? parent.right : undefined
                            left: drawer.onRight ? undefined : parent.left
                            top: parent.bottom
                        }
                        size: drawer.cornerSize
                        color: Colors.panel
                        corner: drawer.onRight ? "topRight" : "topLeft"
                    }

                    // Content only instantiated while open/animating
                    Loader {
                        id: loader
                        anchors.centerIn: parent
                        active: root.active || root.showProgress > 0.001
                        sourceComponent: VolumeOsdContent {}
                    }
                }
            }
        }
    }
}
