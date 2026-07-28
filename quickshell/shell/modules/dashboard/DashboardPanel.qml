import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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

                // Slide-down open/close (matches caelestia's Wrapper.qml offsetScale
                // mechanism: 0 = open, 1 = closed, driving both the panel's anchor
                // margin and its opacity together — not a size tween or scale transform)
                property real offsetScale: root.active ? 0 : 1

                Behavior on offsetScale {
                    NumberAnimation {
                        duration: Motion.animationCurves.expressiveDefaultSpatialDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.animationCurves.expressiveDefaultSpatial
                    }
                }

                // Tab state
                readonly property var tabModel: [
                    { text: "Dashboard", iconName: "dashboard", component: dashboardTabComponent },
                    { text: "Media", iconName: "queue_music", component: mediaTabComponent },
                    { text: "Performance", iconName: "speed", component: performanceTabComponent },
                    { text: "Weather", iconName: "cloud", component: weatherTabComponent }
                ]
                property int currentTab: 0
                readonly property bool widthFixed: Config.dashboard.panel.widthMode === "fixed"
                readonly property bool heightFixed: Config.dashboard.panel.heightMode === "fixed"
                // Resting (open) position — flush with the screen top, matching
                // caelestia's Wrapper.qml exactly (topMargin: 0 when open)
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
                // Stays instantiated/visible through the whole close slide,
                // matching caelestia's `visible: offsetScale < 1` — only hides
                // once fully off-screen, never toggled abruptly
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
                        // Content-driven, not a fixed screen fraction — so a tab whose
                        // cards need less room than the ceiling doesn't get stretched
                        // into dead space (caelestia's Wrapper.qml sizes the same way)
                        // Fixed mode flips this: panel dictates height down to the active tab
                        height: root.heightFixed
                            ? Math.min(Config.dashboard.panel.height, (root.screen?.height ?? 800) * 0.95)
                            : Math.min(contentColumn.implicitHeight + 40, (root.screen?.height ?? 800) * 0.85, 900)
                        radius: Motion.rounding.large
                        // Top corners square so the fillets can merge them into the bar
                        topLeftRadius: 0
                        topRightRadius: 0
                        color: Colors.panel
                        // No border — a Rectangle can't outline only three sides, and
                        // the top edge must merge into the bar. Matches the sidebar
                        // and session backdrops, which are borderless too
                        clip: true

                        opacity: 1 - root.offsetScale

                        Behavior on height {
                            NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                        }

                        // Hover-to-stay-open: cancels a pending hover-close
                        // scheduled by leaving the bar pill while the cursor
                        // is in transit down into the panel
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
                                onTabSelected: i => root.currentTab = i
                            }

                            DashboardTabView {
                                id: tabView

                                model: root.tabModel
                                currentIndex: root.currentTab
                                heightFixed: root.heightFixed
                                panelShown: root.active || root.visible
                                onTabSelected: i => root.currentTab = i
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

