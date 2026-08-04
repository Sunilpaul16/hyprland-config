import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Window thumbnail
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
    required property Item overviewContent
    required property int sourceWorkspaceId

    readonly property var ipc: root.toplevel?.lastIpcObject ?? ({})
    readonly property var atArr: root.ipc.at ?? [0, 0]
    readonly property var sizeArr: root.ipc.size ?? [0, 0]
    readonly property string iconName: AppIcons.resolve(root.ipc.class ?? "")
    readonly property bool beingDragged: root.overviewContent.dragActive && root.overviewContent.dragAddress === root.ipc.address

    x: Math.max(0, (root.atArr[0] - root.monX) / root.monLogicalWidth * root.cardWidth)
    y: Math.max(0, (root.atArr[1] - root.monY) / root.monLogicalHeight * root.cardHeight)
    width: Math.max(1, root.sizeArr[0] / root.monLogicalWidth * root.cardWidth)
    height: Math.max(1, root.sizeArr[1] / root.monLogicalHeight * root.cardHeight)
    opacity: root.beingDragged ? 0.35 : 1

    Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    // Snapshot capture
    ScreencopyView {
        anchors.fill: parent
        captureSource: root.overviewActive ? (root.toplevel?.wayland ?? null) : null
        live: false
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
        id: iconBadge

        readonly property real baseSize: Math.min(root.width, root.height)
        readonly property bool compact: baseSize < 70
        readonly property real badgeSize: Math.max(14, Math.min(32, baseSize * (compact ? 0.35 : 0.15)))

        visible: root.iconName !== ""
        anchors { right: parent.right; bottom: parent.bottom; margins: Motion.spacing.tiny }
        width: badgeSize
        height: badgeSize
        radius: width * 0.3
        color: Colors.panel

        Behavior on width { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        Behavior on height { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Image {
            anchors.centerIn: parent
            source: root.iconName ? Quickshell.iconPath(root.iconName, "") : ""
            sourceSize.width: iconBadge.badgeSize * 0.7
            sourceSize.height: iconBadge.badgeSize * 0.7
            smooth: true
        }
    }

    // Click, middle-click, drag
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        readonly property int dragThreshold: 8
        property real pressX: 0
        property real pressY: 0
        property bool dragStarted: false

        onPressed: mouse => {
            hoverArea.pressX = mouse.x;
            hoverArea.pressY = mouse.y;
            hoverArea.dragStarted = false;
        }

        onPositionChanged: mouse => {
            if (!(mouse.buttons & Qt.LeftButton))
                return;
            if (!hoverArea.dragStarted) {
                const moved = Math.hypot(mouse.x - hoverArea.pressX, mouse.y - hoverArea.pressY);
                if (moved < hoverArea.dragThreshold)
                    return;
                hoverArea.dragStarted = true;
                root.overviewContent.beginDrag(hoverArea, mouse, root.ipc.address, root.sourceWorkspaceId, root.iconName);
            } else {
                root.overviewContent.updateDragPosition(hoverArea, mouse);
            }
        }

        onReleased: {
            if (hoverArea.dragStarted)
                root.overviewContent.releaseDrag();
        }

        onClicked: mouse => {
            if (hoverArea.dragStarted) {
                hoverArea.dragStarted = false;
                return;
            }
            if (mouse.button === Qt.MiddleButton) {
                Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${root.ipc.address}" })`);
                return;
            }
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:${root.ipc.address}" })`);
            OverviewState.open = false;
        }
    }
}
