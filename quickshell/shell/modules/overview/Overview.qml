import QtQuick
import Quickshell
import "../../services"
import "../../components"

// Overview overlay
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: OverlayWindow {
                id: root
                screen: panelLoader.modelData
                state: OverviewState
                namespace: "quickshell-overview"
                maskItem: panel

                onDismissed: OverviewState.open = false
                onEscapePressed: OverviewState.open = false

                // Panel
                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(content.implicitWidth + 56, (root.screen?.width ?? 1280) * 0.92)
                    height: content.implicitHeight + 56
                    radius: Motion.rounding.large
                    color: Colors.panel
                    border.width: 1
                    border.color: Colors.outline

                    opacity: root.showProgress
                    scale: 0.96 + 0.04 * root.showProgress
                    transformOrigin: Item.Center

                    Content {
                        id: content
                        anchors.centerIn: parent
                        screen: root.screen
                        active: root.active
                    }
                }
            }
        }
    }
}
