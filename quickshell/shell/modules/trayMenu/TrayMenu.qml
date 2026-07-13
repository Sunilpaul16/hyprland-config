import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Custom-rendered tray context-menu overlay (QsMenuOpener-driven, plain
// QML — not a native platform menu, see TrayMenuState.qml for why)
PanelWindow {
    id: root

    // Visibility state
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: TrayMenuState.open && root.isFocusedScreen

    property real showProgress: active ? 1 : 0

    Behavior on showProgress {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    // Positioning
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
    WlrLayershell.namespace: "quickshell-tray-menu"
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: TrayMenuState.close()
    }

    // Focus scope
    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: TrayMenuState.close()

        // Absorb clicks on panel
        MouseArea {
            anchors.fill: panel
            onClicked: {}
        }

        // Panel, anchored near the click point (clamped to stay onscreen)
        Rectangle {
            id: panel

            x: Math.max(8, Math.min(TrayMenuState.anchorX, root.width - implicitWidth - 8))
            y: Math.max(8, Math.min(TrayMenuState.anchorY + 14, root.height - implicitHeight - 8))
            implicitWidth: Math.max(160, list.implicitWidth + 12)
            implicitHeight: list.implicitHeight + 12
            radius: 12
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            opacity: root.showProgress
            scale: 0.96 + 0.04 * root.showProgress
            transformOrigin: Item.TopLeft

            // Menu entries list
            Column {
                id: list
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: TrayMenuState.entries

                    TrayMenuItem {
                        required property var modelData
                        entry: modelData
                        width: list.width
                    }
                }
            }
        }
    }
}
