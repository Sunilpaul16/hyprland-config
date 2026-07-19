import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Right sidebar overlay window
PanelWindow {
    id: root

    // Visibility state
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: SidebarRightState.open && root.isFocusedScreen

    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
    }

    // Right-edge stack registration — innermost panel, always flush to
    // the edge itself, but other panels need to know its open+width to
    // offset past it
    readonly property int edgeMargin: 8
    readonly property real registeredWidth: backdrop.width + edgeMargin

    onActiveChanged: RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth)
    Component.onCompleted: RightEdgeStack.register(root.screen, "sidebar", root.active, registeredWidth)

    // Positioning
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Window setup
    exclusiveZone: 0
    color: "transparent"
    visible: showProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-sidebar-right"
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: SidebarRightState.open = false
    }

    // Focus scope
    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: SidebarRightState.open = false

        // Absorb clicks on the sidebar itself so they don't fall through
        // to the full-screen close catcher above.
        MouseArea {
            anchors.fill: backdrop
            onClicked: {}
        }

        // Sidebar backdrop (slide-in panel background) — shrink-wraps to
        // content height rather than always stretching full monitor height,
        // capped so it never overflows past the screen edges
        Rectangle {
            id: backdrop
            anchors { top: parent.top; right: parent.right; margins: root.edgeMargin }
            width: 360
            height: Math.min(column.implicitHeight + 24, parent.height - root.edgeMargin * 2)
            radius: 20
            color: Colors.background
            opacity: root.showProgress
            transform: Translate { x: (1 - root.showProgress) * 24 }

            Behavior on height {
                NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
            }
        }


        // Scrollable card content
        Flickable {
            anchors.fill: backdrop
            anchors.margins: 12

            opacity: root.showProgress
            transform: Translate { x: (1 - root.showProgress) * 24 }

            contentWidth: width
            contentHeight: column.implicitHeight
            clip: true

            // Card stack
            ColumnLayout {
                id: column
                width: parent.width
                spacing: 12

                NotificationsCard { Layout.fillWidth: true }
                KeepAwakeCard { Layout.fillWidth: true }
                ScreenRecorderCard { Layout.fillWidth: true; visible: ScreenRecorderCardState.enabled }
                QuickTogglesCard { Layout.fillWidth: true }
            }
        }
    }
}
