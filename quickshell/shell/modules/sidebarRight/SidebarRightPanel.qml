import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Right sidebar: Notifications / Keep Awake / Screen Recorder / Quick
// Toggles. Static shell for now — every card inside is a visual placeholder,
// no live data wiring. Window is fullscreen (all 4 sides anchored) purely so
// a click-outside-dismiss MouseArea has somewhere to catch clicks — the
// visible card stack itself is still pinned to a fixed-width right-hand
// strip via the `backdrop` Rectangle below. Mirrors NotifPanel.qml's
// click-outside structure exactly (outer catcher -> focus scope -> absorbing
// MouseArea sized to the visual card -> the card).
PanelWindow {
    id: root

    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: SidebarRightState.open && root.isFocusedScreen

    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

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

        // Statically-declared backdrop, NOT loader-created — anchored
        // straight to this Item (guaranteed full window size), so it never
        // depends on a dynamically-loaded item correctly picking up the
        // Loader's size. The first fix put this same Rectangle as the
        // Loader's sourceComponent root, which still left the fill broken
        // (verified visually — not just re-read as code), so ownership of
        // the fill is moved out of the Loader entirely. Now that the window
        // is fullscreen, this Rectangle is also what pins the visible card
        // stack to a fixed-width right-hand strip instead of the whole
        // screen.
        Rectangle {
            id: backdrop
            anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: 8 }
            width: 360
            radius: 20
            color: Colors.background
            opacity: root.showProgress
            transform: Translate { x: (1 - root.showProgress) * 24 }
        }

        Loader {
            id: contentLoader
            active: root.showProgress > 0.001
            anchors.fill: backdrop
            anchors.margins: 12

            opacity: root.showProgress
            transform: Translate { x: (1 - root.showProgress) * 24 }

            sourceComponent: Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true

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
}
