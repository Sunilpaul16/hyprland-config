import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"
import "../../components"

// Notification icon — image, app icon, or flat glyph fallback
Rectangle {
    id: root

    required property Notif notif

    readonly property bool hasImage: notif.image.length > 0
    readonly property bool hasAppIcon: notif.appIcon.length > 0
    readonly property bool hasGlyph: notif.materialIcon.length > 0

    width: 26
    height: 26
    radius: width / 2
    color: notif.critical ? Colors.error : Colors.background
    clip: true

    Image {
        anchors.fill: parent
        visible: root.hasImage
        source: root.hasImage ? StringUtils.resolveNotifImage(root.notif.image) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    IconImage {
        anchors.centerIn: parent
        width: 15
        height: 15
        visible: !root.hasImage && root.hasAppIcon
        asynchronous: true
        source: root.hasAppIcon ? Quickshell.iconPath(root.notif.appIcon, "dialog-information") : ""
    }

    // Shell-raised toasts name a Material Symbol instead of shipping an icon
    MaterialIcon {
        anchors.centerIn: parent
        visible: !root.hasImage && !root.hasAppIcon && root.hasGlyph
        text: root.notif.materialIcon
        color: root.notif.critical ? Colors.textOnError : Colors.primary
        font.pixelSize: Motion.fontSize.title
    }

    // Flat monochrome fallback glyph, not a colorful emoji
    StyledText {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        visible: !root.hasImage && !root.hasAppIcon && !root.hasGlyph
        text: "i"
        color: root.notif.critical ? Colors.textOnError : Colors.primary
        font.pixelSize: Motion.fontSize.label
        font.bold: true
    }
}
