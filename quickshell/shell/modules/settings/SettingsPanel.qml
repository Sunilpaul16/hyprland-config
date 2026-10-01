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

                // Allocate navigation before calculating the preferred width.
                readonly property real availableWidth: screenW * 0.9
                readonly property int navigationWidth: Math.min(
                    Config.settings.navWidth,
                    availableWidth < 900 ? 200
                        : availableWidth < 1200 ? 240
                        : Config.settings.navWidth)

                readonly property int chromeWidth: 18 * 4
                readonly property real panelWidth: Math.max(1, Math.round(
                    Math.min(navigationWidth + Config.settings.maxContentWidth
                        + chromeWidth, availableWidth)))
                readonly property real panelHeight: Math.max(1, Math.round(
                    Math.min(content.naturalHeight,
                        screenH * Config.settings.heightMult, screenH * 0.9)))

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
                        navigationWidth: root.navigationWidth
                    }
                }
            }
        }
    }
}
