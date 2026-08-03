import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../services"
import "../../components"

// Wallpaper preview header
ColumnLayout {
    id: root

    required property real cappedWidth

    // Span page column
    Layout.preferredWidth: cappedWidth

    spacing: Motion.spacing.wide

    // Wallpaper preview
    Item {
        id: preview
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Math.min(root.cappedWidth * 0.72, 470)
        implicitHeight: Math.round(implicitWidth * 9 / 16)

        // OpacityMask rounding
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

        // Missing wallpaper fallback
        ColumnLayout {
            anchors.centerIn: parent
            visible: previewImage.status !== Image.Ready
            spacing: Motion.spacing.tiny

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "hide_image"
                color: Colors.textMuted
                font.pixelSize: 42
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "No wallpaper preview"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.label
            }
        }
    }

    // Sub-navigation
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Motion.spacing.medium

        PillButton {
            live: true
            icon: "wallpaper"
            text: "Wallpapers"
            highlighted: true
            onClicked: SettingsState.openSubPage("wallpapers")
        }

        // Inert
        PillButton {
            icon: "palette"
            text: "Colours"
        }
    }
}
