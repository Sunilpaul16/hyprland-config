import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Live window thumbnail (positioned + sized from Hyprland IPC geometry)
Item {
    id: root

    required property var toplevel // HyprlandToplevel
    required property real cardWidth
    required property real cardHeight
    required property real monX
    required property real monY
    required property real monLogicalWidth
    required property real monLogicalHeight
    required property bool overviewActive

    readonly property var ipc: root.toplevel?.lastIpcObject ?? ({})
    readonly property var atArr: root.ipc.at ?? [0, 0]
    readonly property var sizeArr: root.ipc.size ?? [0, 0]
    readonly property string iconName: AppIcons.resolve(root.ipc.class ?? "")

    x: Math.max(0, (root.atArr[0] - root.monX) / root.monLogicalWidth * root.cardWidth)
    y: Math.max(0, (root.atArr[1] - root.monY) / root.monLogicalHeight * root.cardHeight)
    width: Math.max(1, root.sizeArr[0] / root.monLogicalWidth * root.cardWidth)
    height: Math.max(1, root.sizeArr[1] / root.monLogicalHeight * root.cardHeight)

    // Live capture -- only wired up while the overview is actually open
    ScreencopyView {
        anchors.fill: parent
        captureSource: root.overviewActive ? (root.toplevel?.wayland ?? null) : null
        live: true
    }

    // Hover tint
    Rectangle {
        anchors.fill: parent
        color: Colors.primary
        opacity: hoverArea.containsMouse ? 0.15 : 0
        border.width: 1
        border.color: Colors.outline

        Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    // App icon badge
    Rectangle {
        visible: root.iconName !== ""
        anchors { right: parent.right; bottom: parent.bottom; margins: 4 }
        width: 20
        height: 20
        radius: 6
        color: Colors.background

        Image {
            anchors.centerIn: parent
            anchors.margins: 2
            source: root.iconName ? Quickshell.iconPath(root.iconName, "") : ""
            sourceSize.width: 14
            sourceSize.height: 14
            smooth: true
        }
    }

    // Click to focus window, middle-click to close it (overview stays open)
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${root.ipc.address}" })`);
                return;
            }
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:${root.ipc.address}" })`);
            OverviewState.open = false;
        }
    }
}
