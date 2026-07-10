import QtQuick
import Quickshell
import "../"

// Multi-mode launcher content: app search (default), a ">"-prefixed command
// list, and the wallpaper carousel — all sharing one search field and one
// results area, styled after caelestia's Content.qml/ContentList.qml routing.
//
// The mode isn't a separate stored flag — it's derived from the search
// text's prefix, same as caelestia does it:
//   - no ">" prefix           -> "apps"
//   - ">wallpaper" prefix     -> "wallpaper"
//   - ">clip" prefix          -> "clip" (clipboard history, see Cliphist.qml)
//   - any other ">" prefix    -> "commands" (the list of available modes)
// Selecting a command rewrites the text to `>{name} `, which this same
// computation then picks up on its own — no explicit mode-switch code needed.
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

    // Refresh the clipboard list right as we enter clip mode (no background
    // trigger in Cliphist.qml -- see its header comment for why), same
    // moment CheatsheetState.onOpenChanged calls Binds.refresh().
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

    // Clip-mode "/token" actions -- a map instead of a hardcoded if so a
    // second one (e.g. "/wipe-images") can be added later as just another
    // entry, no branching rework needed. Matched on the *trimmed, exact*
    // clipQuery only ("/cl" while still typing towards "/clear" matches
    // nothing, same as any other unmatched fuzzy query -- see clipResults).
    readonly property var clipActions: ({
        "/clear": {
            icon: "\u{1F5D1}\u{FE0F}",
            label: count => `Clear all clipboard history (${count} ${count === 1 ? "entry" : "entries"})`,
            execute: () => {
                Cliphist.wipe();
                // Drop back to a plain ">clip " query so the (now empty)
                // real list shows instead of re-matching this same action.
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

    // --- Sizing -----------------------------------------------------------
    // Apps/commands are a narrow vertical list; wallpaper is the wide
    // horizontal carousel. Both share the same chrome (padding + gap +
    // search bar), so the panel smoothly resizes between the two shapes as
    // the mode changes.
    readonly property int panelPad: 20
    readonly property int searchGap: 14
    readonly property int searchHeight: 48
    readonly property int chromeHeight: panelPad * 2 + searchGap + searchHeight

    readonly property int wallpaperPanelWidth: 820
    readonly property int wallpaperRowHeight: 130
    readonly property int appPanelWidth: 460
    readonly property int listItemHeight: 56
    // Clip rows get up to 3 wrapped lines (see ClipItem.qml) instead of
    // AppItem/CommandItem's single line, so they need a taller fixed row.
    readonly property int clipItemHeight: 76
    readonly property int listSpacing: 4
    readonly property int maxListItems: 8
    // Clip rows are taller (76px, up to 3 lines) than apps/commands (56px,
    // 1 line) -- 8 of them made the panel uncomfortably tall, so clip mode
    // caps at fewer visible rows before it scrolls.
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

    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    // --- Actions (shared by both Enter-on-current and click-on-a-specific-row) ---
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

    // Copying an entry back makes the standing `wl-paste --watch cliphist
    // store` watcher store it again a moment later, so it reappears at the
    // top as "most recent" -- known behaviour, not a bug (see Cliphist.qml).
    // Action rows (see clipActionRow above) run their own execute() instead
    // and stay open rather than closing the launcher like a real copy does.
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

    // No secondary-action convention exists anywhere else in this launcher
    // (AppItem/CommandItem only have `activated`) -- Shift+Enter/Shift+click
    // is a new one, scoped to clip mode only. Stays open and in clip mode
    // (unlike copy, which closes the launcher): deleteEntry() already
    // refreshes Cliphist.entries itself on exit, so the list updates in place.
    // No-op on an action row -- there's no cliphist entry behind it to delete.
    function deleteCurrentClip(): void {
        const row = content.clipResults[verticalList.currentIndex];
        if (!row || row.isAction)
            return;
        Cliphist.deleteEntry(row.entry);
    }

    // Live-preview while browsing: --preview only swaps the displayed
    // wallpaper (mpvpaper) and skips matugen/kitty/gtk/hyprctl-reload. That
    // skip matters here specifically: the full pipeline regenerates
    // ~/.config/quickshell/bar/Colors.qml, which lives inside the directory
    // Quickshell hot-reloads on any change — running the full pipeline on
    // every debounced preview would reset the whole quickshell config
    // (LauncherState included) and silently close this picker after the very
    // first preview. See switchwall's own header comment for the same note.
    function previewWallpaper(entry): void {
        if (!entry)
            return;
        Quickshell.execDetached(["/home/spaul16/.local/bin/switchwall", "--preview", entry.path]);
    }

    // Confirming always runs the full pipeline (colors/theme included), not
    // just the fast preview — the reload it triggers is harmless here since
    // we're closing the picker anyway.
    function confirmSelection(entry): void {
        applyDebounce.stop();
        if (entry)
            Quickshell.execDetached(["/home/spaul16/.local/bin/switchwall", entry.path]);
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

    // switchwall is heavy (mpvpaper relaunch + matugen + python colorgen +
    // hyprctl reload) — never run it on every keypress/hover tick. Only once
    // the selection has rested for 300ms; restarting the timer (rather than
    // letting a second one queue up) is what gives us "cancel if it moves
    // again before firing."
    Timer {
        id: applyDebounce
        interval: 300
        onTriggered: content.previewWallpaper(content.wallpaperResults[row.currentIndex])
    }

    // Called only from explicit user navigation (arrow keys / hover) — not
    // from model/currentIndex changes in general, so opening the overlay or
    // typing a search query never triggers an unwanted wallpaper switch.
    function requestPreview(): void {
        applyDebounce.restart();
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        // Swallows clicks on blank panel space so they don't fall through
        // to Launcher.qml's full-screen click-outside-to-dismiss MouseArea.
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: resultsArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: searchBg.top
            anchors.margins: content.panelPad
            anchors.bottomMargin: content.searchGap

            // --- Wallpaper mode: horizontal carousel + caption -------------
            Item {
                anchors.fill: parent
                visible: content.mode === "wallpaper"

                ListView {
                    id: row

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: content.wallpaperRowHeight

                    orientation: ListView.Horizontal
                    spacing: 16
                    clip: false

                    // Keeps the current card horizontally centered in the
                    // row as selection moves, like caelestia's PathView does.
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

            // --- Apps/commands mode: vertical list -------------------------
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

            Text {
                anchors.centerIn: parent
                visible: content.currentModeResults.length === 0
                text: content.mode === "wallpaper" ? "No wallpapers found" : (content.mode === "commands" ? "No commands found" : (content.mode === "clip" ? "No clipboard entries found" : "No apps found"))
                color: Colors.textMuted
                font.pixelSize: 15
            }
        }

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

    // Refocus the search field whenever the overlay is (re)shown, seeded
    // with whichever entry point was used (LauncherState.pendingText — plain
    // openApps() leaves it empty, openWallpaper() seeds ">wallpaper ", see
    // LauncherState.qml). Opening does NOT trigger a wallpaper preview —
    // only explicit nav (Keys.onLeft/RightPressed, hoverActivated) calls
    // requestPreview(), so just showing the picker never switches your
    // wallpaper out from under you.
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
