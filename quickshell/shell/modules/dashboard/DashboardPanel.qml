import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

// Dashboard overlay window
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
                readonly property bool isOwnerScreen: ScreenOwner.owns(DashboardState, root.screen)
                readonly property bool active: DashboardState.open && root.isOwnerScreen

                // Slide-down open/close: 0 = open, 1 = closed, driving anchor margin and opacity together
                property real offsetScale: root.active ? 0 : 1

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Motion.animationCurves.expressiveDefaultSpatialDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.animationCurves.expressiveDefaultSpatial
                    }
                }

                // Tab state — allTabs is the full set, tabModel what the bar and
                // view actually get, so a hidden tab leaves no gap behind
                readonly property var allTabs: [
                    { id: "dashboard", text: "Dashboard", iconName: "dashboard", component: dashboardTabComponent, enabled: Config.dashboard.tabs.showDashboard },
                    { id: "media", text: "Media", iconName: "queue_music", component: mediaTabComponent, enabled: Config.dashboard.tabs.showMedia },
                    { id: "performance", text: "Performance", iconName: "speed", component: performanceTabComponent, enabled: Config.dashboard.tabs.showPerformance },
                    { id: "weather", text: "Weather", iconName: "cloud", component: weatherTabComponent, enabled: Config.dashboard.tabs.showWeather }
                ]
                readonly property var tabModel: {
                    const shown = root.allTabs.filter(t => t.enabled);
                    // The settings page won't hide the last tab, but a hand-edited
                    // config can — falling back beats a panel with no tab bar
                    return shown.length > 0 ? shown : root.allTabs;
                }

                // Held as an id, not an index — hiding a tab reindexes the model; falls back to the first tab when the held one is hidden
                property string currentTabId: Config.dashboard.panel.defaultTab
                readonly property int currentTab: {
                    const i = root.tabModel.findIndex(t => t.id === root.currentTabId);
                    return i >= 0 ? i : 0;
                }
                readonly property bool widthFixed: Config.dashboard.panel.widthMode === "fixed"
                readonly property bool heightFixed: Config.dashboard.panel.heightMode === "fixed"
                // Resting (open) position — flush with the screen top
                readonly property real restingTopMargin: 0
                readonly property int cornerSize: 14

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
                // Stays visible through the whole close slide, hiding only once fully off-screen
                visible: offsetScale < 1

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-dashboard"
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
                        DashboardState.open = false;
                    }
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: DashboardState.open = false

                    // Panel
                    Rectangle {
                        id: panel

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: root.restingTopMargin - (panel.height + 5) * root.offsetScale
                        width: root.widthFixed
                            ? Math.min(Config.dashboard.panel.width, (root.screen?.width ?? 1280) * 0.95)
                            : Math.min(Math.max(tabView.currentPaneWidth + 40, 700), (root.screen?.width ?? 1280) * 0.85, 1400)
                        // Content-driven, not a screen fraction, so a narrow tab isn't stretched into dead space
                        // Fixed mode flips this: panel dictates height down to the active tab
                        height: root.heightFixed
                            ? Math.min(Config.dashboard.panel.height, (root.screen?.height ?? 800) * 0.95)
                            : Math.min(contentColumn.implicitHeight + 40, (root.screen?.height ?? 800) * 0.85, 900)
                        radius: Motion.rounding.large
                        // Top corners square so the fillets can merge them into the bar
                        topLeftRadius: 0
                        topRightRadius: 0
                        color: Colors.panel
                        // No border — a Rectangle can't outline only three sides, and the top edge must merge into the bar
                        clip: true

                        opacity: 1 - root.offsetScale

                        Behavior on height {
                            NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                        }

                        // Hover-to-stay-open: cancels the close the bar pill scheduled while the cursor is in transit into the panel
                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered)
                                    DashboardState.cancelHoverClose();
                                else
                                    DashboardState.scheduleHoverClose();
                            }
                        }

                        ColumnLayout {
                            id: contentColumn

                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            DashboardTabBar {
                                model: root.tabModel
                                currentIndex: root.currentTab
                                onTabSelected: i => root.currentTabId = root.tabModel[i].id
                            }

                            DashboardTabView {
                                id: tabView

                                model: root.tabModel
                                currentIndex: root.currentTab
                                heightFixed: root.heightFixed
                                panelShown: root.active || root.visible
                                onTabSelected: i => root.currentTabId = root.tabModel[i].id
                            }
                        }
                    }

                    // Concave fillets merging the panel's top corners into the bar
                    // above. Siblings, not children — panel has clip: true
                    Corner {
                        anchors { right: panel.left; top: panel.top }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "topRight"
                        opacity: panel.opacity
                    }

                    Corner {
                        anchors { left: panel.right; top: panel.top }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "topLeft"
                        opacity: panel.opacity
                    }
                }

                // Tab pages
                Component {
                    id: dashboardTabComponent
                    DashTab {}
                }

                Component {
                    id: mediaTabComponent
                    MediaTab {}
                }

                Component {
                    id: performanceTabComponent
                    PerformanceTab {}
                }

                Component {
                    id: weatherTabComponent
                    WeatherTab {}
                }

            }
        }
    }
}

