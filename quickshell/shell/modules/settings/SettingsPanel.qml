import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

// Settings overlay window
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
                readonly property bool isOwnerScreen: ScreenOwner.owns(SettingsState, root.screen)
                readonly property bool active: SettingsState.open && root.isOwnerScreen

                property real showProgress: active ? 1 : 0

                Behavior on showProgress {
                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                }

                // Panel geometry — 16:9 at ~72% of screen height, floored at the
                // size the two-column layout stops being usable (caelestia's
                // NexusTokens uses the same heightMult/ratio/minWidth shape)
                readonly property real screenW: root.screen?.width ?? 1280
                readonly property real screenH: root.screen?.height ?? 800
                // Both axes scale by one factor, never clamped independently —
                // on a portrait/rotated output the 16:9 target overflows the
                // width ceiling, and clamping width alone leaves a tall sliver
                readonly property real fitScale: Math.min(1, (screenW * 0.9) / (screenH * 0.72 * 16 / 9))
                readonly property real panelHeight: Math.max(500, Math.round(screenH * 0.72 * fitScale))
                readonly property real panelWidth: Math.max(800, Math.round(panelHeight * 16 / 9))

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
                WlrLayershell.namespace: "quickshell-settings"
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
                        SettingsState.open = false;
                    }
                }

                // Focus scope — a FocusScope, not a plain Item: the nav pane's
                // search field sets focus on open, and a plain Item holding
                // `focus: active` would win it back and swallow every keystroke
                FocusScope {
                    anchors.fill: parent
                    focus: root.active
                    // A sub-page swallows the first Escape; the panel closes on the next
            Keys.onEscapePressed: {
                if (SettingsState.subPage)
                    SettingsState.closeSubPage();
                else
                    SettingsState.open = false;
            }

                    // Panel
                    Rectangle {
                        id: panel

                        anchors.centerIn: parent
                        width: root.panelWidth
                        height: root.panelHeight
                        radius: 22
                        color: Colors.background
                        border.width: 1
                        border.color: Colors.outlineVariant
                        clip: true

                        opacity: root.showProgress
                        scale: 0.96 + 0.04 * root.showProgress
                        transformOrigin: Item.Center

                        Content {
                            anchors.fill: parent
                            panelActive: root.active
                        }
                    }
                }
            }
        }
    }
}
