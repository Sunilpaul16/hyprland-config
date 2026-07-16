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

        // Sidebar backdrop (slide-in panel background)
        Rectangle {
            id: backdrop
            anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: 8 }
            width: 360
            radius: 20
            color: Colors.background
            opacity: root.showProgress
            transform: Translate { x: (1 - root.showProgress) * 24 }
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
                SystemCard { Layout.fillWidth: true }
                QuickTogglesRow { Layout.fillWidth: true }
            }
        }
    }
}
