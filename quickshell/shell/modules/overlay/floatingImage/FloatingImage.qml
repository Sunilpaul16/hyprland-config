import QtQuick
import "../"
import "../../../services"
import "../../../components"

// Floating image widget
OverlayWidget {
    id: root

    readonly property var cfg: Config.overlay.floatingImage
    readonly property string resolved: root.cfg.source ? Directories.resolve(root.cfg.source) : ""
    readonly property bool hasImage: root.resolved !== "" && image.status === Image.Ready

    identifier: "floatingImage"
    label: "Image"
    showBackground: !root.hasImage

    AnimatedImage {
        id: image
        source: root.resolved ? `file://${root.resolved}` : ""
        visible: root.hasImage
        playing: visible
        asynchronous: true
        cache: false

        width: implicitWidth * root.cfg.scale
        height: implicitHeight * root.cfg.scale

        // Scroll to scale
        WheelHandler {
            enabled: root.editing
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const step = event.angleDelta.y > 0 ? 0.1 : -0.1;
                Config.overlay.floatingImage.scale = Math.max(0.1, Math.min(5, root.cfg.scale + step));
            }
        }
    }

    // Empty state
    Column {
        visible: !root.hasImage
        spacing: Motion.spacing.small
        padding: Motion.spacing.normal

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "imagesmode"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.display
        }

        StyledText {
            text: root.resolved ? "Image failed to load" : "Set overlay.floatingImage.source"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.small
        }
    }
}
