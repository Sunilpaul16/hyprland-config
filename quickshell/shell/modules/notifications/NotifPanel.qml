import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Notification history panel overlay
PanelWindow {
    id: root

    // Visibility state
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor
    readonly property bool active: NotifPanelState.open && root.isFocusedScreen

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

    color: "transparent"
    exclusiveZone: 0
    visible: showProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-panel"
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: NotifPanelState.open = false
    }

    // Focus scope
    Item {
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: NotifPanelState.open = false

        // Absorb clicks on panel
        MouseArea {
            anchors.fill: panel
            onClicked: {}
        }

        // Panel
        Rectangle {
            id: panel

            readonly property int maxListHeight: root.height - 96 - header.implicitHeight - 26

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 48
            anchors.rightMargin: 14
            implicitWidth: 360
            implicitHeight: header.implicitHeight + 16 + Math.max(list.contentHeight, empty.implicitHeight) + 32
            radius: 18
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            opacity: root.showProgress
            scale: 0.96 + 0.04 * root.showProgress
            transformOrigin: Item.TopRight

            // Header: title + clear-all
            Item {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                implicitHeight: Math.max(titleText.implicitHeight, clearBtn.implicitHeight)

                Text {
                    id: titleText
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    color: Colors.text
                    font.pixelSize: 15
                    font.bold: true
                }

                Rectangle {
                    id: clearBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Notifs.list.length > 0
                    radius: 8
                    color: clearArea.containsMouse ? Colors.outline : Colors.surface
                    implicitWidth: clearText.implicitWidth + 20
                    implicitHeight: 26

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: Colors.text
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            // Empty state
            Text {
                id: empty
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.topMargin: 10
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                visible: Notifs.list.length === 0
                text: "No notifications"
                color: Colors.textMuted
                font.pixelSize: 13
            }

            // History list
            ListView {
                id: list
                anchors { left: parent.left; right: parent.right; top: header.bottom; margins: 16 }
                anchors.topMargin: 10
                height: Math.min(contentHeight, panel.maxListHeight)
                visible: Notifs.list.length > 0
                interactive: contentHeight > height
                spacing: 8
                clip: true

                model: ScriptModel {
                    values: Notifs.list.filter(n => !n.closed)
                }

                delegate: NotifCard {
                    width: list.width
                }
            }
        }
    }
}
