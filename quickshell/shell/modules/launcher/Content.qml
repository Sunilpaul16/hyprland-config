import QtQuick
import Quickshell
import "../../services"


// Launcher content
Item {
    id: content

    // --- Mode -----------------------------------------------------------
    readonly property string mode: {
        const text = input.text;
        if (!text.startsWith(">"))
            return "apps";
        if (text.startsWith(">wallpaper"))
            return "wallpaper";
        if (text.startsWith(">clip"))
            return "clip";
        return "commands";
    }

    onModeChanged: if (mode === "clip") Cliphist.refresh()

    readonly property string commandQuery: input.text.slice(1)
    readonly property string wallpaperQuery: {
        const rest = input.text.slice(">wallpaper".length);
        return rest.startsWith(" ") ? rest.slice(1) : rest;
    }
    readonly property string clipQuery: {
        const rest = input.text.slice(">clip".length);
        return rest.startsWith(" ") ? rest.slice(1) : rest;
    }

    readonly property var appResults: Apps.query(input.text)
    readonly property var commandResults: Commands.query(commandQuery)
    readonly property var wallpaperResults: Wallpapers.query(wallpaperQuery)

    // Clip special actions (e.g. /clear)
    readonly property var clipActions: ({
        "/clear": {
            icon: "\u{1F5D1}\u{FE0F}",
            label: count => `Clear all clipboard history (${count} ${count === 1 ? "entry" : "entries"})`,
            execute: () => {
                Cliphist.wipe();
                input.text = ">clip ";
                input.cursorPosition = input.text.length;
            }
        }
    })

    readonly property var clipActionRow: {
        const token = content.clipQuery.trim();
        const action = content.clipActions[token];
        if (!action)
            return null;
        return {
            isAction: true,
            icon: action.icon,
            label: action.label(Cliphist.entries.length),
            execute: action.execute
        };
    }

    readonly property var clipResults: content.clipActionRow ? [content.clipActionRow] : Cliphist.query(clipQuery)
    readonly property var currentModeResults: mode === "wallpaper" ? wallpaperResults : (mode === "commands" ? commandResults : (mode === "clip" ? clipResults : appResults))


    // Panel sizing constants
    readonly property int panelPad: 20
    readonly property int searchGap: 14
    readonly property int searchHeight: 48
    readonly property int chromeHeight: panelPad * 2 + searchGap + searchHeight

    readonly property int wallpaperPanelWidth: 820
    readonly property int wallpaperRowHeight: 130
    readonly property int appPanelWidth: 460
    readonly property int listItemHeight: 56

    readonly property int clipItemHeight: 76
    readonly property int listSpacing: 4
    readonly property int maxListItems: 8

    readonly property int maxClipItems: 6

    implicitWidth: mode === "wallpaper" ? wallpaperPanelWidth : appPanelWidth
    implicitHeight: {
        if (mode === "wallpaper")
            return chromeHeight + wallpaperRowHeight + 4 + caption.implicitHeight;
        const cap = mode === "clip" ? maxClipItems : maxListItems;
        const n = Math.max(1, Math.min(cap, currentModeResults.length));
        const itemHeight = mode === "clip" ? clipItemHeight : listItemHeight;
        return chromeHeight + n * itemHeight + (n - 1) * listSpacing;
    }

    Behavior on implicitWidth { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
    Behavior on implicitHeight { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    // Actions per mode
    function launchApp(entry): void {
        if (!entry)
            return;
        Apps.launch(entry);
        LauncherState.open = false;
    }

    function selectCommand(cmd): void {
        if (!cmd)
            return;
        input.text = `>${cmd.name} `;
        input.cursorPosition = input.text.length;
    }

    function copyClip(row): void {
        if (!row)
            return;
        if (row.isAction) {
            row.execute();
            return;
        }
        Cliphist.copy(row.entry);
        LauncherState.open = false;
    }

    function deleteCurrentClip(): void {
        const row = content.clipResults[verticalList.currentIndex];
        if (!row || row.isAction)
            return;
        Cliphist.deleteEntry(row.entry);
    }

    function previewWallpaper(entry): void {
        if (!entry)
            return;
        Quickshell.execDetached([Directories.switchwallScript, "--preview", entry.path]);
    }

    function confirmSelection(entry): void {
        applyDebounce.stop();
        if (entry)
            Quickshell.execDetached([Directories.switchwallScript, entry.path]);
        LauncherState.open = false;
    }

    function activateCurrent(): void {
        if (content.mode === "apps")
            content.launchApp(content.appResults[verticalList.currentIndex]);
        else if (content.mode === "commands")
            content.selectCommand(content.commandResults[verticalList.currentIndex]);
        else if (content.mode === "clip")
            content.copyClip(content.clipResults[verticalList.currentIndex]);
        else
            content.confirmSelection(content.wallpaperResults[row.currentIndex]);
    }

    // Debounced wallpaper preview
    Timer {
        id: applyDebounce
        interval: 300
        onTriggered: content.previewWallpaper(content.wallpaperResults[row.currentIndex])
    }

    function requestPreview(): void {
        applyDebounce.restart();
    }

    // Panel background
    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        // Absorb clicks
        MouseArea {
            anchors.fill: parent
        }

        // Results area
        Item {
            id: resultsArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: searchBg.top
            anchors.margins: content.panelPad
            anchors.bottomMargin: content.searchGap

            // Wallpaper mode
            Item {
                anchors.fill: parent
                visible: content.mode === "wallpaper"

                // Wallpaper carousel
                ListView {
                    id: row

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: content.wallpaperRowHeight

                    orientation: ListView.Horizontal
                    spacing: 16
                    clip: false

                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: (width - 150) / 2
                    preferredHighlightEnd: preferredHighlightBegin + 150

                    model: content.wallpaperResults
                    onModelChanged: currentIndex = count > 0 ? 0 : -1

                    delegate: WallpaperItem {
                        onActivated: content.confirmSelection(modelData)
                        onHoverActivated: {
                            row.currentIndex = index;
                            content.requestPreview();
                        }
                    }
                }

                Text {
                    id: caption
                    anchors.top: row.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (row.currentIndex >= 0 && content.wallpaperResults[row.currentIndex]) ? content.wallpaperResults[row.currentIndex].name : ""
                    color: Colors.text
                    font.pixelSize: 13
                    elide: Text.ElideMiddle
                    width: Math.min(implicitWidth, content.wallpaperPanelWidth - content.panelPad * 2)
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // App/command/clip results list
            ListView {
                id: verticalList

                anchors.fill: parent
                visible: content.mode !== "wallpaper"
                clip: true
                spacing: content.listSpacing

                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: height

                model: content.mode === "commands" ? content.commandResults : (content.mode === "clip" ? content.clipResults : content.appResults)
                onModelChanged: currentIndex = count > 0 ? 0 : -1

                delegate: content.mode === "commands" ? commandItemComponent : (content.mode === "clip" ? clipItemComponent : appItemComponent)

                // Delegate factories per mode
                Component {
                    id: appItemComponent
                    AppItem {
                        isCurrent: ListView.isCurrentItem
                        onActivated: content.launchApp(modelData)
                    }
                }

                Component {
                    id: commandItemComponent
                    CommandItem {
                        isCurrent: ListView.isCurrentItem
                        onActivated: content.selectCommand(modelData)
                    }
                }

                Component {
                    id: clipItemComponent
                    ClipItem {
                        isCurrent: ListView.isCurrentItem
                        onActivated: content.copyClip(modelData)
                        onDeleteRequested: {
                            if (!modelData.isAction)
                                Cliphist.deleteEntry(modelData.entry);
                        }
                    }
                }
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: content.currentModeResults.length === 0
                text: content.mode === "wallpaper" ? "No wallpapers found" : (content.mode === "commands" ? "No commands found" : (content.mode === "clip" ? "No clipboard entries found" : "No apps found"))
                color: Colors.textMuted
                font.pixelSize: 15
            }
        }

        // Search bar
        Rectangle {
            id: searchBg

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: content.panelPad
            height: content.searchHeight
            radius: height / 2
            color: Colors.background

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 44
                anchors.verticalCenter: parent.verticalCenter
                text: content.mode === "wallpaper" ? "Search wallpapers…" : (content.mode === "commands" ? "Type a command…" : (content.mode === "clip" ? "Search clipboard… (Shift+Enter deletes)" : "Search apps…"))
                color: Colors.textMuted
                font.pixelSize: 15
                visible: input.text.length === 0
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{1F50D}"
                font.pixelSize: 14
                opacity: 0.6
            }

            // Search input
            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 44
                anchors.rightMargin: 18
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.text
                font.pixelSize: 15
                clip: true
                focus: true

                Keys.onEscapePressed: LauncherState.open = false
                Keys.onReturnPressed: event => {
                    if (content.mode === "clip" && (event.modifiers & Qt.ShiftModifier))
                        content.deleteCurrentClip();
                    else
                        content.activateCurrent();
                }
                Keys.onEnterPressed: event => {
                    if (content.mode === "clip" && (event.modifiers & Qt.ShiftModifier))
                        content.deleteCurrentClip();
                    else
                        content.activateCurrent();
                }

                Keys.onUpPressed: if (content.mode !== "wallpaper") verticalList.decrementCurrentIndex()
                Keys.onDownPressed: if (content.mode !== "wallpaper") verticalList.incrementCurrentIndex()
                Keys.onLeftPressed: {
                    if (content.mode === "wallpaper") {
                        row.decrementCurrentIndex();
                        content.requestPreview();
                    }
                }
                Keys.onRightPressed: {
                    if (content.mode === "wallpaper") {
                        row.incrementCurrentIndex();
                        content.requestPreview();
                    }
                }
            }
        }
    }

    // Sync from launcher state on open
    Connections {
        target: LauncherState
        function onOpenChanged() {
            if (LauncherState.open) {
                input.text = LauncherState.pendingText;
                input.cursorPosition = input.text.length;
                input.forceActiveFocus();
            }
        }
    }
}
