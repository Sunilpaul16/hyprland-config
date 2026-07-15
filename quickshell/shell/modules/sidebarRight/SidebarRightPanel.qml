import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Right sidebar: Notifications / Keep Awake / Screen Recorder / Quick
// Toggles. Static shell for now — every card inside is a visual placeholder,
// no live data wiring. True top/right/bottom-anchored strip (not a floating
// card like NotifPanel), matching end-4's sidebarRight approach.
//
// No click-outside-dismiss: this window only covers the sidebar's own
// width, so it can't catch clicks landing elsewhere without a second
// fullscreen input-capture layer (the trick NotifPanel.qml uses). Close via
// the bar toggle or Escape only — flagged as a known gap, build later if
// wanted.
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
        right: true
        bottom: true
    }

    implicitWidth: 360
    exclusiveZone: 0
    color: "transparent"
    visible: showProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-sidebar-right"
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: SidebarRightState.open = false

        // Statically-declared backdrop, NOT loader-created — anchored
        // straight to this Item (guaranteed full window size), so it never
        // depends on a dynamically-loaded item correctly picking up the
        // Loader's size. The first fix put this same Rectangle as the
        // Loader's sourceComponent root, which still left the fill broken
        // (verified visually — not just re-read as code), so ownership of
        // the fill is moved out of the Loader entirely.
        Rectangle {
            id: backdrop
            anchors.fill: parent
            anchors.margins: 8
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
                    KeepAwakeCard { Layout.fillWidth: true }
                    ScreenRecorderCard { Layout.fillWidth: true }
                    QuickTogglesRow { Layout.fillWidth: true }
                }
            }
        }
    }
}
