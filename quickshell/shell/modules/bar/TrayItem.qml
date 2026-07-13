import QtQuick
import Quickshell.Services.SystemTray
import "../../services"

// One system tray icon: left-click activates, right-click opens its
// context menu (falls back to secondaryActivate() if it has none)
Item {
    id: root

    required property SystemTrayItem item

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

        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // Left-click activate, right-click menu
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
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
            }
        }
    }

    // Simple hand-rolled tooltip (no QtQuick.Controls dependency)
    Timer {
        id: tooltipDelay
        interval: 500
        onTriggered: tooltip.visible = true
    }

    // Show/hide tooltip on hover
    Connections {
        target: hoverArea
        function onContainsMouseChanged(): void {
            if (hoverArea.containsMouse && root.tooltipStr.length > 0)
                tooltipDelay.start();
            else {
                tooltipDelay.stop();
                tooltip.visible = false;
            }
        }
    }

    // Tooltip
    Rectangle {
        id: tooltip
        visible: false
        anchors.top: parent.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 8
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline
        implicitWidth: tooltipText.implicitWidth + 20
        implicitHeight: tooltipText.implicitHeight + 14

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tooltipStr
            color: Colors.text
            font.pixelSize: 12
        }
    }
}
