import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../services"
import "../sidebarRight"

// Wallpaper picker, reached from Wallpaper & style's Wallpapers pill.
// Modelled on caelestia's WallpaperSelect — Browse/Random above a large
// current-wallpaper preview and a grid of the local collection
ScrollPage {
    id: root

    title: "Wallpapers"
    isSubPage: true

    // Hovering a tile themes the shell with that wallpaper's palette without
    // applying anything; leaving the grid puts the real one back
    property string hoveredPath: ""

    onHoveredPathChanged: {
        if (root.hoveredPath)
            previewTimer.restart();
        else {
            previewTimer.stop();
            ColorsLoader.clearPreview();
        }
    }

    // Abandoning the page mid-hover must not strand the preview
    Component.onDestruction: ColorsLoader.clearPreview()

    Timer {
        id: previewTimer

        interval: Config.wallpaper.previewDelay
        repeat: false
        onTriggered: ColorsLoader.preview(root.hoveredPath)
    }

    readonly property int columns: 3
    readonly property int gridSpacing: 12
    readonly property int tileWidth: Math.floor((root.cappedWidth - root.gridSpacing * (root.columns - 1)) / root.columns)

    // Sub-navigation
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10

        PillButton {
            live: true
            icon: "search"
            text: "Browse"
            onClicked: {
                SettingsState.open = false;
                LauncherState.openWallpaper();
            }
        }

        PillButton {
            live: true
            icon: "shuffle"
            text: "Random"
            highlighted: true
            onClicked: Wallpapers.applyRandom()
        }
    }

    SectionLabel {
        text: "Current wallpaper"
    }

    // Large preview of what's applied now — caelestia shows a bundled
    // "featured" image here; the one actually in use is more informative
    Item {
        id: hero

        Layout.fillWidth: true
        implicitHeight: Math.round(width * 0.3)

        // OpacityMask over a plain Image — ClippingRectangle renders nothing
        // inside these overlays
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: hero.width
                height: hero.height
                radius: 18
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.layer
        }

        Image {
            id: heroImage

            anchors.fill: parent
            source: Wallpapers.currentPreview
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }

        Text {
            anchors.centerIn: parent
            visible: heroImage.status !== Image.Ready
            text: "No wallpaper set"
            color: Colors.textMuted
            font.pixelSize: 13
        }
    }

    SectionLabel {
        text: ColorsLoader.previewing ? "Local wallpapers · previewing colours" : `Local wallpapers · ${Wallpapers.list.length}`
    }

    // Collection grid
    Flow {
        Layout.fillWidth: true
        spacing: root.gridSpacing

        Repeater {
            model: Wallpapers.list

            Item {
                id: tile

                required property var modelData

                readonly property bool isCurrent: modelData.path === Wallpapers.current

                width: root.tileWidth
                height: Math.round(root.tileWidth * 9 / 16)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: tile.width
                        height: tile.height
                        radius: 14
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Colors.layer
                }

                Image {
                    id: thumb

                    anchors.fill: parent
                    source: tile.modelData.thumbPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: root.tileWidth * 2
                }

                // Video thumbnails are generated on demand and may not exist
                // on a first run — redraw when the scan reports one ready
                Connections {
                    target: Wallpapers
                    function onThumbnailReady(path: string) {
                        if (path !== tile.modelData.path)
                            return;
                        // Force a reload; the source string is unchanged
                        thumb.source = "";
                        thumb.source = tile.modelData.thumbPath;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: tile.isCurrent || tileHover.containsMouse
                    color: "transparent"
                    border.width: tile.isCurrent ? 3 : 2
                    border.color: tile.isCurrent ? Colors.primary : Colors.outline
                }

                // Name plate, so a grid of similar thumbnails stays navigable
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 26
                    color: Qt.alpha(Colors.background, 0.82)
                    visible: tileHover.containsMouse || tile.isCurrent

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        text: tile.modelData.label
                        color: tile.isCurrent ? Colors.primary : Colors.text
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    visible: tile.modelData.isVideo
                    text: "movie"
                    color: Colors.text
                    font.pixelSize: 16
                }

                MouseArea {
                    id: tileHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoveredPath = tile.modelData.path
                    onExited: {
                        if (root.hoveredPath === tile.modelData.path)
                            root.hoveredPath = "";
                    }
                    onClicked: {
                        // Applying supersedes the preview; clearing after would
                        // fight the real theme landing a moment later
                        root.hoveredPath = "";
                        ColorsLoader.clearPreview();
                        Wallpapers.apply(tile.modelData.path);
                    }
                }
            }
        }
    }

    // Empty state
    SettingRow {
        visible: Wallpapers.list.length === 0
        first: true
        last: true
        live: true
        label: "No wallpapers found"
        subtext: Directories.wallpaperDir
    }
}
