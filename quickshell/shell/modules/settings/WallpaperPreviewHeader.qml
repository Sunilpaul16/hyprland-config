import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../services"
import "../../components"

// Wallpaper preview header
ColumnLayout {
    id: root

    required property real cappedWidth

    // Span page column
    Layout.preferredWidth: cappedWidth

    spacing: Motion.spacing.wide

    // Match the physical desk layout: DP-2 is the portrait monitor on the right.
    readonly property var screens: [...Quickshell.screens].sort((a, b) => {
        if (a.name === "DP-2") return 1;
        if (b.name === "DP-2") return -1;
        return a.name.localeCompare(b.name);
    })
    readonly property int previewGap: Motion.spacing.large
    readonly property real aspectTotal: screens.reduce((sum, screen) =>
        sum + Math.max(0.4, Math.min(2, screen.width / Math.max(1, screen.height))), 0)
    readonly property real previewHeight: Math.min(250,
        (root.cappedWidth - root.previewGap * Math.max(0, screens.length - 1)) / Math.max(1, root.aspectTotal))

    // One crop preview per monitor, using its logical orientation.
    Row {
        id: previews
        Layout.alignment: Qt.AlignHCenter
        spacing: root.previewGap

        Repeater {
            model: root.screens

            ClippingRectangle {
                id: monitorPreview

                required property var modelData
                readonly property real screenAspect: Math.max(0.4,
                    Math.min(2, modelData.width / Math.max(1, modelData.height)))

                width: Math.round(root.previewHeight * screenAspect)
                height: Math.round(root.previewHeight)
                radius: Motion.rounding.large

                Rectangle {
                    anchors.fill: parent
                    color: Colors.layer
                }

                Image {
                    id: previewImage

                    readonly property real sourceAspect: status === Image.Ready && implicitHeight > 0
                        ? implicitWidth / implicitHeight : monitorPreview.screenAspect
                    readonly property bool cropsHorizontally: sourceAspect > monitorPreview.screenAspect

                    source: Wallpapers.currentPreview
                    width: cropsHorizontally ? monitorPreview.height * sourceAspect : monitorPreview.width
                    height: cropsHorizontally ? monitorPreview.height : monitorPreview.width / Math.max(0.01, sourceAspect)
                    x: cropsHorizontally ? -(width - monitorPreview.width) * WallpaperFraming.current
                        : (monitorPreview.width - width) / 2
                    y: cropsHorizontally ? 0 : -(height - monitorPreview.height) / 2
                    fillMode: Image.Stretch
                    asynchronous: true
                    cache: false
                }

                MouseArea {
                    id: framingDrag

                    anchors.fill: parent
                    enabled: monitorPreview.screenAspect < 1 && Wallpapers.current.length > 0
                    hoverEnabled: enabled
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    property real pressX: 0
                    property real pressOffset: 0.5

                    onPressed: mouse => {
                        framingDrag.pressX = mouse.x;
                        framingDrag.pressOffset = WallpaperFraming.current;
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        const delta = (mouse.x - framingDrag.pressX) / Math.max(1, width);
                        WallpaperFraming.setFor(Wallpapers.current, framingDrag.pressOffset - delta);
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: Motion.spacing.small
                    implicitWidth: monitorLabel.implicitWidth + 12
                    implicitHeight: monitorLabel.implicitHeight + 6
                    radius: height / 2
                    color: Qt.alpha(Colors.floatingOpaque, 0.86)

                    StyledText {
                        id: monitorLabel
                        anchors.centerIn: parent
                        text: `${monitorPreview.modelData.name} · ${monitorPreview.screenAspect < 1 ? "Portrait" : "Landscape"}`
                        color: Colors.text
                        font.pixelSize: Motion.fontSize.tiny
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Motion.spacing.small
                    visible: monitorPreview.screenAspect < 1 && (framingDrag.containsMouse || framingDrag.pressed)
                    implicitWidth: framingLabel.implicitWidth + 12
                    implicitHeight: framingLabel.implicitHeight + 6
                    radius: height / 2
                    color: Qt.alpha(Colors.floatingOpaque, 0.86)

                    StyledText {
                        id: framingLabel
                        anchors.centerIn: parent
                        text: `Drag to frame · ${Math.round(WallpaperFraming.current * 100)}%`
                        color: Colors.text
                        font.pixelSize: Motion.fontSize.tiny
                    }
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
                        font.pixelSize: Math.min(42, monitorPreview.width * 0.3)
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        visible: monitorPreview.width >= 160
                        text: "No wallpaper preview"
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.label
                    }
                }
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

        PillButton {
            live: true
            icon: "palette"
            text: "Colours"
            onClicked: SettingsState.openSubPage("schemes")
        }
    }
}
