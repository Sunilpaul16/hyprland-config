import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../services"
import "../../components"

// Wallpaper picker
ScrollPage {
    id: root

    title: "Wallpapers"
    isSubPage: true

    // Hover previews palette
    property string hoveredPath: ""

    onHoveredPathChanged: {
        if (root.hoveredPath)
            previewTimer.restart();
        else {
            previewTimer.stop();
            ColorsLoader.clearPreview();
        }
    }

    // Clear on destroy
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

    // Matching wallpapers
    readonly property var filtered: Wallpapers.query(searchInput.text)

    // Search visibility
    property bool searchOpen: false

    onSearchOpenChanged: {
        if (root.searchOpen)
            searchInput.forceActiveFocus();
        else
            searchInput.text = "";
    }

    // Sub-navigation
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Motion.spacing.medium

        PillButton {
            live: true
            icon: "search"
            text: "Browse"
            highlighted: true
            onClicked: root.searchOpen = !root.searchOpen
        }

        PillButton {
            live: true
            icon: "shuffle"
            text: "Random"
            highlighted: true
            onClicked: Wallpapers.applyRandom()
        }
    }

    // Search field
    Rectangle {
        Layout.fillWidth: true
        visible: root.searchOpen
        implicitHeight: 44
        radius: height / 2
        color: Colors.layer
        border.width: 1
        border.color: searchInput.activeFocus ? Colors.primary : Colors.outlineVariant

        Behavior on border.color { CAnim {} }

        MaterialIcon {
            id: searchIcon

            anchors.left: parent.left
            anchors.leftMargin: Motion.spacing.xlarge
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.display
        }

        StyledText {
            anchors.left: searchIcon.right
            anchors.leftMargin: Motion.spacing.large
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text.length === 0
            text: "Search wallpapers"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.title
        }

        TextInput {
            id: searchInput

            anchors.fill: parent
            anchors.leftMargin: 48
            anchors.rightMargin: clearAction.width + Motion.spacing.xlarge
            verticalAlignment: TextInput.AlignVCenter
            color: Colors.text
            font.pixelSize: Motion.fontSize.title
            clip: true

            // Filtering drops hovered tile
            onTextChanged: root.hoveredPath = ""

            Keys.onEscapePressed: event => {
                if (searchInput.text.length > 0)
                    searchInput.text = "";
                else
                    root.searchOpen = false;
                event.accepted = true;
            }
        }

        IconAction {
            id: clearAction

            anchors.right: parent.right
            anchors.rightMargin: Motion.spacing.large
            anchors.verticalCenter: parent.verticalCenter
            iconName: "close"
            iconColor: Colors.textMuted
            onTriggered: {
                if (searchInput.text.length > 0)
                    searchInput.text = "";
                else
                    root.searchOpen = false;
            }
        }
    }

    SectionLabel {
        text: "Current wallpaper"
    }

    // Large preview
    ClippingRectangle {
        id: hero

        Layout.fillWidth: true
        implicitHeight: Math.round(width * 0.3)

        radius: Motion.rounding.large

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

        StyledText {
            anchors.centerIn: parent
            visible: heroImage.status !== Image.Ready
            text: "No wallpaper set"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.label
        }
    }

    SectionLabel {
        text: ColorsLoader.previewing ? "Local wallpapers · previewing colours" : `Local wallpapers · ${root.filtered.length}`
    }

    // Collection grid
    Flow {
        id: flow

        Layout.fillWidth: true
        spacing: root.gridSpacing

        Repeater {
            model: root.filtered

            Loader {
                id: tileLoader

                required property var modelData

                width: root.tileWidth
                height: Math.round(root.tileWidth * 9 / 16)
                // Keep only nearby image delegates alive. The Flow still owns
                // geometry for every result, while off-screen tiles stay cheap.
                active: flow.y + tileLoader.y + tileLoader.height >= root.viewport.contentY - tileLoader.height * 2
                    && flow.y + tileLoader.y <= root.viewport.contentY + root.viewport.height + tileLoader.height * 2

                sourceComponent: ClippingRectangle {
                    id: tile

                    readonly property var modelData: tileLoader.modelData
                    readonly property bool isCurrent: modelData.path === Wallpapers.current

                    radius: Motion.rounding.card

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

                    // Redraw when ready
                    Connections {
                        target: Wallpapers
                        function onThumbnailReady(path: string) {
                            if (path !== tile.modelData.path)
                                return;
                            thumb.source = "";
                            thumb.source = tile.modelData.thumbPath;
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: tile.isCurrent || tileHover.containsMouse
                        radius: Motion.rounding.card
                        color: "transparent"
                        border.width: tile.isCurrent ? 3 : 2
                        border.color: tile.isCurrent ? Colors.primary : Colors.outline
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 26
                        color: Qt.alpha(Colors.background, 0.82)
                        visible: tileHover.containsMouse || tile.isCurrent

                        StyledText {
                            anchors.fill: parent
                            anchors.leftMargin: Motion.spacing.normal
                            anchors.rightMargin: Motion.spacing.normal
                            verticalAlignment: Text.AlignVCenter
                            text: tile.modelData.label
                            color: tile.isCurrent ? Colors.primary : Colors.text
                            font.pixelSize: Motion.fontSize.small
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Motion.spacing.small
                        visible: tile.modelData.isVideo
                        text: "movie"
                        color: Colors.text
                        font.pixelSize: Motion.fontSize.large
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
                            root.hoveredPath = "";
                            ColorsLoader.clearPreview();
                            Wallpapers.apply(tile.modelData.path);
                        }
                    }
                }
            }
        }
    }

    // Empty state
    SettingRow {
        visible: root.filtered.length === 0
        first: true
        last: true
        live: true
        label: searchInput.text.length > 0 ? "No wallpapers match" : "No wallpapers found"
        subtext: searchInput.text.length > 0 ? searchInput.text : Directories.wallpaperDir
    }
}
