import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

// Focused-window icon + title, styled after ~/shell's ActiveWindow.qml
// (read-only reference) but stripped down to just the title -- their
// hover-popout is a whole separate feature this doesn't attempt.
//
// Per-monitor last-active, via LastActive.qml -- see that file's header for
// why a real per-monitor "last focused window" isn't a native Hyprland
// property and has to be tracked ourselves off activeToplevelChanged
// events. `current` is whatever LastActive.lastFor() resolves to for this
// monitor: the real last-focused window here, a fallback if that one
// closed/moved away, or nothing if this monitor was never focused (cold
// start) or is genuinely empty.
Item {
    id: root
    property var screen

    readonly property var monitor: Hyprland.monitorFor(root.screen)
    readonly property var current: LastActive.lastFor(root.monitor)

    // Full strength only when `current` is *also* the globally-focused
    // window right now -- i.e. this monitor currently has real input focus.
    // Otherwise it's a remembered/fallback title, dimmed with the same
    // Colors.textMuted tone Workspaces.qml uses for empty/unowned pills.
    readonly property bool isGloballyActive: !!root.current && root.current === Hyprland.activeToplevel

    readonly property string title: root.current?.title ?? ""
    readonly property string wmClass: root.current?.lastIpcObject?.class ?? ""
    readonly property string icon: AppIcons.resolve(root.wmClass)

    // Exposed so Bar.qml can hide the whole SectionPill (not just this
    // Item) when there's nothing to show -- an empty padded pill would
    // still read as a stray blob in the left zone otherwise.
    readonly property bool hasContent: !!root.current && root.title.length > 0

    readonly property int maxTitleWidth: 220

    visible: root.hasContent
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 8
        opacity: root.isGloballyActive ? 1 : 0.6

        Behavior on opacity { NumberAnimation { duration: 150 } }

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

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
