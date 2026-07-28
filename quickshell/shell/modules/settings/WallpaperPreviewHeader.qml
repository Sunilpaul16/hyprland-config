import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../services"
import "../../components"

// Wallpaper preview plus the Wallpapers/Colours sub-navigation.
// Spacing matches ScrollPage's own column so wrapping these two changes nothing
ColumnLayout {
    id: root

    required property real cappedWidth

    spacing: 14

    // Wallpaper preview
    Item {
        id: preview
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Math.min(root.cappedWidth * 0.72, 470)
        implicitHeight: Math.round(implicitWidth * 9 / 16)

        // Rounded via OpacityMask on a plain Image — a
        // ClippingRectangle renders nothing inside these overlays
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: preview.width
                height: preview.height
                radius: Motion.rounding.large
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.layer
        }

        Image {
            id: previewImage

            anchors.fill: parent
            source: Wallpapers.currentPreview
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }

        // Fallback while the wallpaper (or its thumb) is missing
        ColumnLayout {
            anchors.centerIn: parent
            visible: previewImage.status !== Image.Ready
            spacing: 4

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "hide_image"
                color: Colors.textMuted
                font.pixelSize: 42
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No wallpaper preview"
                color: Colors.textMuted
                font.pixelSize: 13
            }
        }
    }

    // Sub-navigation
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10

        PillButton {
            live: true
            icon: "wallpaper"
            text: "Wallpapers"
            highlighted: true
            onClicked: SettingsState.openSubPage("wallpapers")
        }

        // caelestia's equivalent opens a "page under construction" stub, so
        // there is nothing to port behind this one yet
        PillButton {
            icon: "palette"
            text: "Colours"
        }
    }
}
