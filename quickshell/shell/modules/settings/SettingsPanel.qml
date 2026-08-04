import QtQuick
import Quickshell
import "../../services"
import "../../components"

// Settings overlay window
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: OverlayWindow {
                id: root
                screen: panelLoader.modelData
                state: SettingsState
                namespace: "quickshell-settings"
                maskItem: panel

                onDismissed: SettingsState.open = false
                onEscapePressed: {
                    if (SettingsState.subPage)
                        SettingsState.closeSubPage();
                    else
                        SettingsState.open = false;
                }

                // Panel geometry
                readonly property real screenW: root.screen?.width ?? 1280
                readonly property real screenH: root.screen?.height ?? 800

                // Chrome width
                readonly property int chromeWidth: 18 * 4
                readonly property real targetWidth: Config.settings.navWidth + Config.settings.maxContentWidth + chromeWidth
                readonly property real targetHeight: Math.min(content.naturalHeight, screenH * Config.settings.heightMult)

                // Shared fit scale
                readonly property real fitScale: Math.min(1, (screenW * 0.9) / targetWidth, (screenH * 0.9) / targetHeight)
                readonly property real panelWidth: Math.max(700, Math.round(targetWidth * fitScale))
                readonly property real panelHeight: Math.max(460, Math.round(targetHeight * fitScale))

                // Panel
                Rectangle {
                    id: panel

                    // Menu reparent surface
                    property bool isSettingsCard: true

                    anchors.centerIn: parent
                    width: root.panelWidth
                    height: root.panelHeight
                    radius: Motion.rounding.page
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
