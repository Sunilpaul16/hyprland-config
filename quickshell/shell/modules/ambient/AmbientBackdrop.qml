import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

// A non-interactive layer above the wallpaper and below application windows.
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: PanelWindow {
                id: root

                screen: panelLoader.modelData
                anchors { top: true; right: true; bottom: true; left: true }
                color: "transparent"
                visible: AmbientState.opacity > 0.001
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "quickshell-ambient"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                mask: Region { item: null }

                Rectangle {
                    anchors.fill: parent
                    opacity: AmbientState.opacity

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0; color: AmbientState.topTint }
                        GradientStop { position: 1; color: AmbientState.bottomTint }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.scaled(1800); easing.type: Motion.deliberateEasing }
                    }
                }
            }
        }
    }
}
