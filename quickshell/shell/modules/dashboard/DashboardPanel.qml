import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../sidebarRight"
import "../bar"

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
                        radius: 18
                        // Top corners square so the fillets can merge them into the bar
                        topLeftRadius: 0
                        topRightRadius: 0
                        color: Colors.background
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

                            // Tab bar
                            Item {
                                id: tabBar

                                // Breathing room the hover fill expands into, above and
                                // below the icon/label stack
                                readonly property int indicatorSpacing: 5

                                Layout.fillWidth: true
                                implicitHeight: buttonsRow.implicitHeight + tabBar.indicatorSpacing * 2 + activeIndicator.height + separator.height

                                RowLayout {
                                    id: buttonsRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: tabBar.indicatorSpacing
                                    spacing: 0

                                    Repeater {
                                        id: tabRepeater

                                        model: root.tabModel

                                        delegate: Item {
                                            id: tabButton

                                            required property int index
                                            required property var modelData
                                            readonly property bool current: index === root.currentTab
                                            // The underline hugs the label, not the whole slot
                                            readonly property real indicatorWidth: Math.max(tabIcon.implicitWidth, tabLabel.implicitWidth)

                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            implicitHeight: tabIcon.implicitHeight + tabLabel.implicitHeight

                                            // Hover fill
                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                height: parent.height + tabBar.indicatorSpacing * 2
                                                radius: Motion.rounding.normal
                                                color: tabHover.containsMouse ? Colors.surface : "transparent"

                                                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                                            }

                                            MaterialIcon {
                                                id: tabIcon
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: tabLabel.top
                                                text: tabButton.modelData.iconName
                                                color: tabButton.current ? Colors.primary : Colors.textMuted
                                                font.pixelSize: 22
                                                fill: tabButton.current ? 1 : 0

                                                Behavior on fill { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
                                            }

                                            Text {
                                                id: tabLabel
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                text: tabButton.modelData.text
                                                color: tabButton.current ? Colors.primary : Colors.textMuted
                                                font.pixelSize: 13
                                            }

                                            MouseArea {
                                                id: tabHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.currentTab = tabButton.index
                                            }
                                        }
                                    }
                                }

                                // Stretchy active-tab underline (comparison.md #39)
                                Rectangle {
                                    id: activeIndicator

                                    // itemAt(), not children[] — RowLayout's internal bookkeeping
                                    // reorders buttonsRow.children, so position-based indexing isn't
                                    // reliable (see tabView.currentPane below for the same issue with
                                    // paneRow's Loaders). tabRepeater.count is read only to force
                                    // re-evaluation once the Repeater finishes populating.
                                    readonly property Item targetItem: {
                                        tabRepeater.count;
                                        return tabRepeater.itemAt(root.currentTab);
                                    }

                                    anchors.top: buttonsRow.bottom
                                    anchors.topMargin: tabBar.indicatorSpacing
                                    height: 3
                                    // Flat-bottomed: it sits directly on the divider below
                                    topLeftRadius: height
                                    topRightRadius: height
                                    bottomLeftRadius: 0
                                    bottomRightRadius: 0
                                    color: Colors.primary

                                    AnimatedTabIndexPair {
                                        id: leftBound
                                        index: activeIndicator.targetItem ? activeIndicator.targetItem.x + (activeIndicator.targetItem.width - activeIndicator.targetItem.indicatorWidth) / 2 : 0
                                    }
                                    AnimatedTabIndexPair {
                                        id: rightBound
                                        index: activeIndicator.targetItem ? activeIndicator.targetItem.x + (activeIndicator.targetItem.width + activeIndicator.targetItem.indicatorWidth) / 2 : 0
                                    }

                                    x: Math.min(leftBound.idx1, leftBound.idx2)
                                    width: Math.max(rightBound.idx1, rightBound.idx2) - x
                                }

                                // Divider closing off the bar
                                Rectangle {
                                    id: separator
                                    anchors.top: activeIndicator.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 1
                                    color: Colors.outlineVariant
                                }

                                // Wheel-to-switch-tab
                                MouseArea {
                                    z: 2
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    onWheel: event => {
                                        if (event.angleDelta.y < 0)
                                            root.currentTab = Math.min(root.currentTab + 1, root.tabModel.length - 1);
                                        else
                                            root.currentTab = Math.max(root.currentTab - 1, 0);
                                    }
                                }
                            }

                            // Horizontally-flickable tab content (one pane per tab, swipeable)
                            Flickable {
                                id: tabView

                                readonly property real paneWidth: width
                                // itemAt(), not children[] — unlike buttonsRow's plain Rectangle
                                // delegates, these Loaders' async `active` toggling reorders
                                // paneRow.children, so position-based indexing is unreliable here.
                                // repeater.count is read only to force re-evaluation once the
                                // Repeater finishes populating (itemAt() alone isn't tracked)
                                readonly property Item currentPane: {
                                    repeater.count;
                                    return repeater.itemAt(root.currentTab);
                                }
                                property real currentPaneHeight: currentPane?.height ?? 0
                                // Read off the pane's own content, never off paneWidth — the
                                // panel's auto width feeds this, so anything derived from
                                // tabView.width here would deadlock at 0
                                readonly property real livePaneWidth: currentPane?.item?.implicitWidth ?? 0
                                // Latched to the last real width: the pane is destroyed while the
                                // dashboard is closed, and letting that drop the panel to its floor
                                // snaps it narrower mid close-animation
                                property real currentPaneWidth: 0
                                onLivePaneWidthChanged: if (livePaneWidth > 0)
                                    currentPaneWidth = livePaneWidth

                                Layout.fillWidth: true
                                Layout.fillHeight: root.heightFixed
                                Layout.preferredHeight: root.heightFixed ? -1 : currentPaneHeight

                                Behavior on currentPaneHeight {
                                    NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                                }

                                flickableDirection: Flickable.HorizontalFlick
                                contentWidth: paneRow.width
                                contentHeight: height
                                contentX: root.currentTab * paneWidth
                                clip: true

                                Behavior on contentX {
                                    NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                                }

                                onDragEnded: {
                                    const delta = contentX - root.currentTab * paneWidth;
                                    if (delta > paneWidth / 10)
                                        root.currentTab = Math.min(root.currentTab + 1, root.tabModel.length - 1);
                                    else if (delta < -paneWidth / 10)
                                        root.currentTab = Math.max(root.currentTab - 1, 0);
                                    contentX = Qt.binding(() => root.currentTab * tabView.paneWidth);
                                }

                                Item {
                                    id: paneRow
                                    width: root.tabModel.length * tabView.paneWidth
                                    height: tabView.height

                                    Repeater {
                                        id: repeater

                                        model: root.tabModel

                                        // Also keeps whichever adjacent tab is mid-scroll
                                        // during a drag instantiated, not just the current
                                        // tab
                                        delegate: Loader {
                                            id: paneLoader

                                            required property int index
                                            required property var modelData

                                            x: index * tabView.paneWidth
                                            width: tabView.paneWidth
                                            // Own natural content height, not the tallest tab's —
                                            // tabView.currentPaneHeight then follows whichever pane
                                            // is current, animated on switch
                                            // Fixed-height mode flips this: pane fills tabView's height instead
                                            height: root.heightFixed ? tabView.height : (item ? item.implicitHeight : 0)

                                            sourceComponent: modelData.component

                                            // Gate on the panel actually being shown, not just
                                            // index === currentTab: the default currentTab loader
                                            // would otherwise stay active from window construction
                                            // (on every monitor, dashboard closed or not), keeping
                                            // its cards' services polling 24/7 and defeating the
                                            // ref-counted "only poll while referenced" design.
                                            // `active || visible` loads eagerly on open and retains
                                            // content through the close fade-out.
                                            Component.onCompleted: active = Qt.binding(() => {
                                                if (!(root.active || root.visible))
                                                    return false;
                                                if (index === root.currentTab)
                                                    return true;
                                                const vx = Math.floor(tabView.visibleArea.xPosition * tabView.contentWidth);
                                                const vex = Math.floor(vx + tabView.visibleArea.widthRatio * tabView.contentWidth);
                                                return (vx >= x && vx <= x + width) || (vex >= x && vex <= x + width);
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Concave fillets merging the panel's top corners into the bar
                    // above. Siblings, not children — panel has clip: true
                    Corner {
                        anchors { right: panel.left; top: panel.top }
                        size: root.cornerSize
                        color: Colors.background
                        corner: "topRight"
                        opacity: panel.opacity
                    }

                    Corner {
                        anchors { left: panel.right; top: panel.top }
                        size: root.cornerSize
                        color: Colors.background
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

                // idx1 (fast) and idx2 (slow) — min/max of both stretches the indicator instead of sliding it
                component AnimatedTabIndexPair: QtObject {
                    required property real index

                    property real idx1: index
                    property real idx2: index

                    Behavior on idx1 { NumberAnimation { duration: 100; easing.type: Easing.OutSine } }
                    Behavior on idx2 { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
                }
            }
        }
    }
}
