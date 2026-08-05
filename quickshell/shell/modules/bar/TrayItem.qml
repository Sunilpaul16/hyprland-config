import QtQuick
import Quickshell.Services.SystemTray
import "../../services"
import "../../components"

// Tray icon
Item {
    id: root

    required property SystemTrayItem item

    readonly property string tooltipStr: root.item.tooltipTitle.length > 0 ? root.item.tooltipTitle : root.item.title

    readonly property int iconSize: 18

    implicitWidth: 26
    implicitHeight: 26

    // Hover highlight
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.alpha(Colors.primary, 0.3)
        opacity: hoverArea.containsMouse ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    // App pixmap
    Image {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.item.icon
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }

    // Click handling
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.item.activate();
            } else if (mouse.button === Qt.RightButton) {
                if (root.item.hasMenu) {
                    // Anchor to icon
                    const pos = hoverArea.mapToItem(null, 0, 0);
                    TrayMenuState.showAt(root.item, pos.x);
                } else {
                    root.item.secondaryActivate();
                }
            }
        }
    }

    property bool tooltipVisible: false

    // Tooltip delay
    Timer {
        id: tooltipDelay
        interval: 500
        onTriggered: root.tooltipVisible = true
    }

    // Tooltip on hover
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

    // Tooltip popup
    PopupToolTip {
        hoverTarget: root
        text: root.tooltipStr
        shown: root.tooltipVisible
    }
}
