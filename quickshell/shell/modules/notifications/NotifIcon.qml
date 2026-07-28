import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"

// Notification icon — image, app icon, or flat glyph fallback
Rectangle {
    id: root

    required property Notif notif

    readonly property bool hasImage: notif.image.length > 0
    readonly property bool hasAppIcon: notif.appIcon.length > 0

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

    // Flat monochrome fallback glyph, not a colorful emoji
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        visible: !root.hasImage && !root.hasAppIcon
        text: "i"
        color: root.notif.critical ? Colors.textOnError : Colors.primary
        font.pixelSize: 13
        font.bold: true
    }
}
