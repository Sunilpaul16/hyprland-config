import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../sidebarRight"

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
                readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
                readonly property bool active: DashboardState.open && root.isFocusedScreen

                property real showProgress: active ? 1 : 0

                Behavior on showProgress {
                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                }

                // Tab state
                readonly property var tabModel: [
                    { text: "Dashboard", iconName: "dashboard", component: dashboardTabComponent },
                    { text: "Media", iconName: "queue_music", component: mediaTabComponent },
                    { text: "Performance", iconName: "speed", component: performanceTabComponent },
                    { text: "Weather", iconName: "cloud", component: weatherTabComponent }
                ]
                property int currentTab: 0

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
                visible: showProgress > 0.001

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

                        anchors.centerIn: parent
                        width: Math.min((root.screen?.width ?? 1280) * 0.85, 1400)
                        // Content-driven, not a fixed screen fraction — so a tab whose
                        // cards need less room than the ceiling doesn't get stretched
                        // into dead space (caelestia's Wrapper.qml sizes the same way)
                        height: Math.min(contentColumn.implicitHeight + 40, (root.screen?.height ?? 800) * 0.85, 900)
                        radius: 18
                        color: Colors.background
                        border.width: 1
                        border.color: Colors.outline

                        opacity: root.showProgress
                        scale: 0.96 + 0.04 * root.showProgress
                        transformOrigin: Item.Center

                        Behavior on height {
                            NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                        }

                        ColumnLayout {
                            id: contentColumn

                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            // Tab bar
                            Item {
                                id: tabBar
                                Layout.fillWidth: true
                                implicitHeight: buttonsRow.implicitHeight

                                // Stretchy active-tab indicator (comparison.md #39)
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

                                    z: 0
                                    height: parent.height
                                    radius: height / 2
                                    color: Colors.primary

                                    AnimatedTabIndexPair {
                                        id: leftBound
                                        index: activeIndicator.targetItem ? activeIndicator.targetItem.x : 0
                                    }
                                    AnimatedTabIndexPair {
                                        id: rightBound
                                        index: activeIndicator.targetItem ? (activeIndicator.targetItem.x + activeIndicator.targetItem.width) : 0
                                    }

                                    x: Math.min(leftBound.idx1, leftBound.idx2)
                                    width: Math.max(rightBound.idx1, rightBound.idx2) - x
                                }

                                RowLayout {
                                    id: buttonsRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    z: 1
                                    spacing: 8

                                    Repeater {
                                        id: tabRepeater

                                        model: root.tabModel

                                        delegate: Rectangle {
                                            id: tabButton

                                            required property int index
                                            required property var modelData
                                            readonly property bool current: index === root.currentTab

                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            radius: 10
                                            color: "transparent"
                                            implicitHeight: tabLabelRow.implicitHeight + 12

                                            Row {
                                                id: tabLabelRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                MaterialIcon {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: tabButton.modelData.iconName
                                                    color: tabButton.current ? Colors.background : Colors.text
                                                    font.pixelSize: 15
                                                }

                                                Text {
                                                    id: tabLabel
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: tabButton.modelData.text
                                                    color: tabButton.current ? Colors.background : Colors.text
                                                    font.pixelSize: 13
                                                    font.bold: tabButton.current
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.currentTab = tabButton.index
                                            }
                                        }
                                    }
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

                                Layout.fillWidth: true
                                Layout.preferredHeight: currentPaneHeight

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
                                            height: item ? item.implicitHeight : 0

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
