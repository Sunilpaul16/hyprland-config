import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"

PanelWindow {
    id: root

    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: CheatsheetState.open && root.isFocusedScreen

    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0
    visible: showProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-cheatsheet"
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: CheatsheetState.open = false
    }

    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: CheatsheetState.open = false

        MouseArea {
            anchors.fill: panel
            onClicked: {}
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: Math.round((root.screen?.width ?? 800) * 0.7)
            height: Math.round((root.screen?.height ?? 600) * 0.7)
            radius: 18
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            opacity: root.showProgress
            scale: 0.96 + 0.04 * root.showProgress
            transformOrigin: Item.Center

            Content {
                anchors.fill: parent
                anchors.margins: 28
            }
        }
    }
}
