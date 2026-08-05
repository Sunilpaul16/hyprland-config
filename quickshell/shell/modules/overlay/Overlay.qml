import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

// Widget overlay window
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData
            extraCondition: OverlayState.open || OverlayState.hasPinned

            component: PanelWindow {
                id: overlay
                screen: panelLoader.modelData

                readonly property bool isOwnerScreen: ScreenOwner.owns(OverlayState, overlay.screen)
                readonly property bool editing: OverlayState.open && overlay.isOwnerScreen

                // Positioning
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                // Window setup
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: overlay.isOwnerScreen
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-overlay"
                WlrLayershell.keyboardFocus: overlay.editing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Input only while editing
                mask: Region {
                    item: overlay.editing ? content : null
                }

                Content {
                    id: content
                    anchors.fill: parent
                    screen: overlay.screen
                    focus: overlay.editing
                }
            }
        }
    }
}
