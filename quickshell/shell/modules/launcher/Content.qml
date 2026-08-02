import QtQuick
import Quickshell
import "../../services"
import "../../components"


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

    // Wide enough for five slots with one of them enlarged
    // (4 * 150 + 190 + 4 * 16 + 2 * panelPad)
    readonly property int wallpaperPanelWidth: 900
    readonly property int wallpaperRowHeight: 130
    readonly property int appPanelWidth: 460
    readonly property int listItemHeight: 56

    readonly property int clipItemHeight: 76
    readonly property int listSpacing: 4
    readonly property int maxListItems: Config.launcher.maxResults

    readonly property int maxClipItems: Config.launcher.maxClipResults

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

    // Tracks whether a not-yet-confirmed --preview needs reverting on close
    property bool hasPreviewed: false

    // Wallpaper preview lifecycle
    function previewWallpaper(entry): void {
        if (!entry)
            return;
        content.hasPreviewed = true;
        Quickshell.execDetached([Directories.switchwallScript, "--preview", entry.path]);
    }

    function confirmSelection(entry): void {
        applyDebounce.stop();
        content.hasPreviewed = false;
        if (entry)
            Quickshell.execDetached([Directories.switchwallScript, entry.path]);
        LauncherState.open = false;
    }

    function revertPreview(): void {
        applyDebounce.stop(); // a queued preview must not fire after this revert
        if (!content.hasPreviewed)
            return;
        content.hasPreviewed = false;
        // Real switch, not --noswitch — that deliberately never touches the displayed wallpaper
        Quickshell.execDetached(["bash", "-c", `"${Directories.switchwallScript}" "$(cat "${Directories.currentWallpaperFile}")"`]);
    }

    // Acting on the current selection
    function activateCurrent(): void {
        if (content.mode === "apps")
            content.launchApp(content.appResults[verticalList.currentIndex]);
        else if (content.mode === "commands")
            content.selectCommand(content.commandResults[verticalList.currentIndex]);
        else if (content.mode === "clip")
            content.copyClip(content.clipResults[verticalList.currentIndex]);
        else
            content.confirmSelection(content.wallpaperResults[carousel.currentIndex]);
    }

    // Debounced wallpaper preview
    Timer {
        id: applyDebounce
        interval: Config.wallpaper.previewDelay
        onTriggered: content.previewWallpaper(content.wallpaperResults[carousel.currentIndex])
    }

    function requestPreview(): void {
        applyDebounce.restart();
    }

    function navigateWallpaper(delta: int): void {
        if (delta > 0)
            carousel.increment();
        else
            carousel.decrement();
        content.requestPreview();
    }

    // Panel background
    Rectangle {
        id: panelBg

        anchors.fill: parent
        // Off-ladder on purpose: nearest steps are drawer (20) and hero (26), and either is a visible change to the launcher's silhouette
        radius: 24
        // Bottom corners square so the fillets can flare this panel into the
        // screen edge it sits flush against
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Colors.layer
        // No border — a Rectangle can't outline only three sides, and the
        // bottom edge merges into the screen edge via the fillets below

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
            WallpaperCarousel {
                id: carousel

                anchors.fill: parent
                visible: content.mode === "wallpaper"

                results: content.wallpaperResults
                rowHeight: content.wallpaperRowHeight
                panelWidth: content.wallpaperPanelWidth
                panelPad: content.panelPad

                onActivated: entry => content.confirmSelection(entry)
                onNavigate: delta => content.navigateWallpaper(delta)
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
            StyledText {
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
            color: Colors.panel

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 44
                anchors.verticalCenter: parent.verticalCenter
                text: content.mode === "wallpaper" ? "Search wallpapers…" : (content.mode === "commands" ? "Type a command…" : (content.mode === "clip" ? "Search clipboard… (Shift+Enter deletes)" : "Search apps…"))
                color: Colors.textMuted
                font.pixelSize: 15
                visible: input.text.length === 0
            }

            StyledText {
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

                // Ctrl+J/K mirror the arrow keys; Ctrl+N/P are the readline spelling of the same move
                Keys.onPressed: event => {
                    if (!(event.modifiers & Qt.ControlModifier))
                        return;
                    const down = event.key === Qt.Key_J || event.key === Qt.Key_N;
                    const up = event.key === Qt.Key_K || event.key === Qt.Key_P;
                    if (!down && !up)
                        return;
                    if (content.mode === "wallpaper")
                        content.navigateWallpaper(down ? 1 : -1);
                    else if (down)
                        verticalList.incrementCurrentIndex();
                    else
                        verticalList.decrementCurrentIndex();
                    event.accepted = true;
                }

                Keys.onUpPressed: if (content.mode !== "wallpaper") verticalList.decrementCurrentIndex()
                Keys.onDownPressed: if (content.mode !== "wallpaper") verticalList.incrementCurrentIndex()
                Keys.onLeftPressed: if (content.mode === "wallpaper") content.navigateWallpaper(-1)
                Keys.onRightPressed: if (content.mode === "wallpaper") content.navigateWallpaper(1)
            }
        }
    }

    // Sync from launcher state on open; revert an unconfirmed preview on close
    Connections {
        target: LauncherState
        function onOpenChanged() {
            if (LauncherState.open) {
                input.text = LauncherState.pendingText;
                input.cursorPosition = input.text.length;
                input.forceActiveFocus();
            } else {
                content.revertPreview();
            }
        }
    }

    // Concave fillets flaring the panel into the screen edge it rests on.
    // Siblings of the background so they sit outside the panel's own bounds
    Corner {
        anchors { right: parent.left; bottom: parent.bottom }
        size: 14
        color: Colors.layer
        corner: "bottomRight"
    }

    Corner {
        anchors { left: parent.right; bottom: parent.bottom }
        size: 14
        color: Colors.layer
        corner: "bottomLeft"
    }
}

