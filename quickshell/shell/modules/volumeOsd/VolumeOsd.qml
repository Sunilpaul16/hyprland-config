import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../../components"

// Volume OSD
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
                // Startup grace
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

                // Show on change
                function show(): void {
                    if (!root.startupGraceOver || !Config.audio.osdEnabled)
                        return;
                    root.triggered = true;
                    armHideTimer();
                }

                // Arm hide timer
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

                // Click-through mask
                mask: Region {
                    item: drawer
                }

                // Drawer
                Item {
                    id: drawer

                    property bool hovered: false

                    // Flush to edge
                    readonly property int restingMargin: 0
                    readonly property int cornerSize: 14
                    readonly property int contentPadding: 10
                    readonly property int closedMargin: -(drawer.implicitWidth + restingMargin)

                    // Hugged edge
                    readonly property bool onRight: Config.audio.osdEdge !== "left"

                    // Stack offset
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
                    // First-frame fallback
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

                    // Backdrop
                    Rectangle {
                        anchors.fill: parent
                        radius: Motion.rounding.drawer
                        topRightRadius: drawer.onRight ? 0 : Motion.rounding.drawer
                        bottomRightRadius: drawer.onRight ? 0 : Motion.rounding.drawer
                        topLeftRadius: drawer.onRight ? Motion.rounding.drawer : 0
                        bottomLeftRadius: drawer.onRight ? Motion.rounding.drawer : 0
                        color: Colors.panel
                    }

                    // Edge fillets
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

                    // Lazy content
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
