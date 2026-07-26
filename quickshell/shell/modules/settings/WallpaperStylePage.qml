import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../services"
import "../sidebarRight"

// Wallpaper & style page. Layout only — the pills navigate nowhere and the
// switches hold their own state rather than writing any config
PageBase {
    id: root

    title: "Wallpaper & style"

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: column

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: root.cappedWidth
            spacing: 18

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
                        radius: 18
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Colors.surface
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
                    icon: "wallpaper"
                    text: "Wallpapers"
                    highlighted: true
                }

                PillButton {
                    icon: "palette"
                    text: "Colours"
                }
            }

            // Settings group
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                SettingRow {
                    first: true
                    label: "Display wallpaper"

                    ToggleSwitch {
                        checked: true
                    }
                }

                SettingRow {
                    label: "Transparency"
                    subtext: "Base 0.9, layers 0.3"

                    ToggleSwitch {
                        checked: false
                    }
                }

                SettingRow {
                    last: true
                    label: "Dark theme"

                    ToggleSwitch {
                        checked: true
                    }
                }
            }
        }
    }
}
