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

                // Panel geometry — both axes hug the content (nav pane + capped page column, nav list height); an aspect ratio on either axis reintroduces dead space
                readonly property real screenW: root.screen?.width ?? 1280
                readonly property real screenH: root.screen?.height ?? 800

                // Content.qml's `pad` on each side, plus the gap between the
                // two columns and the page area's extra right margin
                readonly property int chromeWidth: 18 * 4
                readonly property real targetWidth: Config.settings.navWidth + Config.settings.maxContentWidth + chromeWidth
                readonly property real targetHeight: Math.min(content.naturalHeight, screenH * Config.settings.heightMult)

                // One factor for both axes — clamping them independently leaves a sliver rather than a smaller panel on a rotated output
                readonly property real fitScale: Math.min(1, (screenW * 0.9) / targetWidth, (screenH * 0.9) / targetHeight)
                readonly property real panelWidth: Math.max(700, Math.round(targetWidth * fitScale))
                readonly property real panelHeight: Math.max(460, Math.round(targetHeight * fitScale))

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

                // A FocusScope, not a plain Item — the nav search field takes focus on open, and a plain Item holding `focus: active` would win it back and swallow keystrokes
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

                        // The surface SelectMenu reparents its dropdown onto — inside this card's clip, above the page's scrolling content
                        property bool isSettingsCard: true

                        anchors.centerIn: parent
                        width: root.panelWidth
                        height: root.panelHeight
                        radius: 22
                        color: Colors.panel
                        border.width: 1
                        border.color: Colors.outlineVariant
                        clip: true

                        opacity: root.showProgress
                        scale: 0.96 + 0.04 * root.showProgress
                        transformOrigin: Item.Center

                        Content {
                            id: content

                            anchors.fill: parent
                            panelActive: root.active
                        }
                    }
                }
            }
        }
    }
}
