import QtQuick
import Quickshell
import "../../services"
import "../../components"

// Launcher overlay window
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: OverlayWindow {
                id: root
                screen: panelLoader.modelData
                state: LauncherState
                namespace: "quickshell-launcher"
                maskItem: content

                onDismissed: LauncherState.open = false

                Content {
                    id: content
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.showProgress
                    scale: 0.94 + 0.06 * root.showProgress
                    transformOrigin: Item.Bottom
                }
            }
        }
    }
}
