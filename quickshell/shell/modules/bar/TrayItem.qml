import QtQuick
import Quickshell.Services.SystemTray
import "../../services"

// Single tray icon: pixmap, hover highlight, click handling, tooltip
Item {
    id: root

    required property SystemTrayItem item

    signal toggleHiddenRequested

    readonly property string tooltipStr: root.item.tooltipTitle.length > 0 ? root.item.tooltipTitle : root.item.title

    implicitWidth: 18
    implicitHeight: 18

    // App-provided pixmap, rendered as-is (not retinted)
    Image {
        anchors.fill: parent
        source: root.item.icon
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }

    // Hover highlight
    Rectangle {
        anchors.fill: parent
        anchors.margins: -5
        radius: 6
        color: Colors.outline
        opacity: hoverArea.containsMouse ? 0.5 : 0
        z: -1

        Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    // Left-click activate, right-click menu, middle-click pin/unpin to the overflow popup
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.item.activate();
            } else if (mouse.button === Qt.RightButton) {
                if (root.item.hasMenu) {
                    const pos = hoverArea.mapToItem(null, mouse.x, mouse.y);
                    TrayMenuState.showAt(root.item, pos.x, pos.y);
                } else {
                    root.item.secondaryActivate();
                }
            } else if (mouse.button === Qt.MiddleButton) {
                root.toggleHiddenRequested();
            }
        }
    }

    property bool tooltipVisible: false

    // Simple hand-rolled tooltip delay (no QtQuick.Controls dependency)
    Timer {
        id: tooltipDelay
        interval: 500
        onTriggered: root.tooltipVisible = true
    }

    // Show/hide tooltip on hover
    Connections {
        target: hoverArea
        function onContainsMouseChanged(): void {
            if (hoverArea.containsMouse && root.tooltipStr.length > 0)
                tooltipDelay.start();
            else {
                tooltipDelay.stop();
                root.tooltipVisible = false;
            }
        }
    }

    // Tooltip — its own PopupWindow, can't be clipped by the bar's bounds
    PopupToolTip {
        hoverTarget: root
        text: root.tooltipStr
        shown: root.tooltipVisible
    }
}
