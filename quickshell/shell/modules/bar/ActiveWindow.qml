import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../services"


// Active window widget
Item {
    id: root
    property var screen

    // Derived window state
    readonly property var monitor: Hyprland.monitorFor(root.screen)
    readonly property var current: LastActive.lastFor(root.monitor)
    readonly property bool isGloballyActive: !!root.current && root.current === Hyprland.activeToplevel

    readonly property string title: root.current?.title ?? ""
    readonly property string wmClass: root.current?.lastIpcObject?.class ?? ""
    readonly property string icon: AppIcons.resolve(root.wmClass)

    readonly property bool hasContent: !!root.current && root.title.length > 0

    readonly property int maxTitleWidth: 220

    visible: root.hasContent
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    // Icon + title
    Row {
        id: row
        spacing: 8
        opacity: root.isGloballyActive ? 1 : 0.6

        Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            source: Quickshell.iconPath(root.icon, "image-missing")
            implicitSize: 18
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTitleWidth)
            text: root.title
            color: root.isGloballyActive ? Colors.text : Colors.textMuted
            font.pixelSize: 13
            elide: Text.ElideRight

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }
    }
}
