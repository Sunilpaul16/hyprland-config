import QtQuick
import "../../services"

// Inline Wi-Fi picker beneath Quick Toggles.
Rectangle {
    id: root

    readonly property bool expanded: SidebarDialogState.wifiOpen
    radius: Motion.rounding.large
    color: Colors.layer
    border.width: 1
    border.color: Colors.outlineVariant
    clip: true
    implicitHeight: root.expanded ? 380 : 0
    opacity: root.expanded ? 1 : 0
    visible: root.expanded || root.implicitHeight > 0

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }
    Behavior on opacity {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 1
        active: root.expanded || root.implicitHeight > 0
        sourceComponent: WifiDialog {}
    }
}
