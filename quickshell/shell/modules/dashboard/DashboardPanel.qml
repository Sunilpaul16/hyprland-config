import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Dashboard overlay window
PanelWindow {
    id: root

    // Visibility state
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: DashboardState.open && root.isFocusedScreen

    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
    }

    // Tab state
    readonly property var tabModel: [
        { text: "Dashboard", component: dashboardTabComponent },
        { text: "Media", component: mediaTabComponent },
        { text: "Performance", component: performanceTabComponent },
        { text: "Weather", component: weatherTabComponent }
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
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: DashboardState.open = false
    }

    // Focus scope
    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: DashboardState.open = false

        // Absorb clicks on the panel itself so they don't fall through
        // to the full-screen close catcher above.
        MouseArea {
            anchors.fill: panel
            onClicked: {}
        }

        // Panel
        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.min((root.screen?.width ?? 1280) * 0.85, 1400)
            height: Math.min((root.screen?.height ?? 800) * 0.85, 900)
            radius: 18
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            opacity: root.showProgress
            scale: 0.96 + 0.04 * root.showProgress
            transformOrigin: Item.Center

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Tab bar
                RowLayout {
                    id: tabBar
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.tabModel

                        delegate: Rectangle {
                            id: tabButton

                            required property int index
                            required property var modelData
                            readonly property bool current: index === root.currentTab

                            radius: 10
                            color: current ? Colors.primary : "transparent"
                            implicitWidth: tabLabel.implicitWidth + 24
                            implicitHeight: tabLabel.implicitHeight + 12

                            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: tabButton.modelData.text
                                color: tabButton.current ? Colors.background : Colors.text
                                font.pixelSize: 13
                                font.bold: tabButton.current
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = tabButton.index
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Horizontally-flickable tab content (one pane per tab, swipeable)
                Flickable {
                    id: tabView

                    readonly property real paneWidth: width

                    Layout.fillWidth: true
                    Layout.fillHeight: true

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
                            model: root.tabModel

                            // Only the current tab (+ whichever adjacent tab is
                            // partially scrolled into view during a drag) is
                            // instantiated — mirrors caelestia-shell's
                            // Tabs.qml/Content.qml activation-window check
                            // (see references/caelestia-dashboard-reference.md,
                            // "Shell structure" section) rather than just
                            // gating on index === currentTab.
                            delegate: Loader {
                                id: paneLoader

                                required property int index
                                required property var modelData

                                x: index * tabView.paneWidth
                                width: tabView.paneWidth
                                height: tabView.height

                                sourceComponent: modelData.component

                                Component.onCompleted: active = Qt.binding(() => {
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
        PlaceholderTab { label: "Weather tab" }
    }

    component PlaceholderTab: Item {
        required property string label

        Text {
            anchors.centerIn: parent
            text: parent.label
            color: Colors.textMuted
            font.pixelSize: 18
        }
    }
}
