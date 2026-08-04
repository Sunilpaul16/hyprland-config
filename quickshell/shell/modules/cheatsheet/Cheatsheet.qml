import QtQuick
import Quickshell
import "../../services"
import "../../components"

// Cheatsheet overlay window
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: OverlayWindow {
                id: root
                screen: panelLoader.modelData
                state: CheatsheetState
                namespace: "quickshell-cheatsheet"
                maskItem: panel

                onDismissed: CheatsheetState.open = false
                onEscapePressed: CheatsheetState.open = false

                // Panel
                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(content.implicitWidth + 56, (root.screen?.width ?? 1280) * 0.9)
                    height: Math.min(content.implicitHeight + 56, (root.screen?.height ?? 800) * 0.85)
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
                    }
                }
            }
        }
    }
}
