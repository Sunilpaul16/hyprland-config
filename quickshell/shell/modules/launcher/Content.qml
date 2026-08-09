import QtQuick
import Quickshell
import "../../services"
import "../../components"


// Launcher content
Item {
    id: content

    // Mode
    readonly property string mode: {
        const text = input.text;
        if (!text.startsWith(">"))
            return "apps";
        if (text.startsWith(">wallpaper"))
            return "wallpaper";
        if (text.startsWith(">clip"))
            return "clip";
        if (text.startsWith(">scheme"))
            return "scheme";
        if (text.startsWith(">variant"))
            return "variant";
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
    readonly property string schemeQuery: {
        const rest = input.text.slice(">scheme".length);
        return rest.startsWith(" ") ? rest.slice(1) : rest;
    }
    readonly property string variantQuery: {
        const rest = input.text.slice(">variant".length);
        return rest.startsWith(" ") ? rest.slice(1) : rest;
    }

    readonly property var appResults: Apps.query(input.text)
    readonly property var commandResults: Commands.query(commandQuery)
    readonly property var wallpaperResults: Wallpapers.query(wallpaperQuery)

    // Presets, dynamic first
    readonly property var schemeResults: {
        const rows = Schemes.query(content.schemeQuery).map(s => ({
            id: s.id,
            label: `${s.scheme.charAt(0).toUpperCase()}${s.scheme.slice(1)} ${s.flavour}`,
            description: s.modes.length > 0 ? s.modes.join(" · ") : s.id,
            surface: s.surface,
            primary: s.primary,
            outline: s.outline
        }));
        const query = content.schemeQuery.trim().toLowerCase();
        const pinned = [];
        if (!query || "dynamic".startsWith(query))
            pinned.push({
                id: "dynamic",
                label: "Dynamic",
                description: "Colours generated from the wallpaper",
                isDynamic: true
            });
        if (!query || "random".startsWith(query))
            pinned.push({
                id: "random",
                label: "Random",
                description: "Any palette, or back to the wallpaper",
                isRandom: true
            });
        return [...pinned, ...rows];
    }

    readonly property var variantResults: SchemeVariants.query(content.variantQuery).map(v => ({
        value: v.value,
        label: v.label,
        icon: v.icon,
        description: v.value === Config.theming.scheme ? `${v.description} · in use` : v.description
    }))

    // Clip actions
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
    readonly property var currentModeResults: {
        if (content.mode === "wallpaper")
            return content.wallpaperResults;
        if (content.mode === "commands")
            return content.commandResults;
        if (content.mode === "clip")
            return content.clipResults;
        if (content.mode === "scheme")
            return content.schemeResults;
        if (content.mode === "variant")
            return content.variantResults;
        return content.appResults;
    }


    // Per-mode copy
    readonly property string placeholderText: {
        if (content.mode === "wallpaper")
            return "Search wallpapers…";
        if (content.mode === "commands")
            return "Type a command…";
        if (content.mode === "clip")
            return "Search clipboard… (Shift+Enter deletes)";
        if (content.mode === "scheme")
            return "Search colour palettes…";
        if (content.mode === "variant")
            return "Search scheme variants…";
        return "Search apps…";
    }

    readonly property string emptyText: {
        if (content.mode === "wallpaper")
            return Wallpapers.loading ? "Loading…" : "No wallpapers found";
        if (content.mode === "commands")
            return "No commands found";
        if (content.mode === "clip")
            return "No clipboard entries found";
        if (content.mode === "scheme")
            return Schemes.available ? "No palettes found" : "No palettes available";
        if (content.mode === "variant")
            return "No variants found";
        return "No apps found";
    }

    // Panel sizing constants
    readonly property int panelPad: 20
    readonly property int searchGap: 14
    readonly property int searchHeight: 48
    readonly property int chromeHeight: panelPad * 2 + searchGap + searchHeight

    // Wallpaper panel width
    readonly property int wallpaperPanelWidth: Config.launcher.wallpaperPanelWidth
    readonly property int appPanelWidth: Config.launcher.panelWidth
    readonly property int listItemHeight: 56

    readonly property int clipItemHeight: 76
    readonly property int listSpacing: 4
    readonly property int maxListItems: Config.launcher.maxResults

    readonly property int maxClipItems: Config.launcher.maxClipResults

    implicitWidth: mode === "wallpaper" ? wallpaperPanelWidth : appPanelWidth
    implicitHeight: {
        if (mode === "wallpaper")
            return chromeHeight + carousel.implicitHeight;
        const cap = mode === "clip" ? maxClipItems : maxListItems;
        const n = Math.max(1, Math.min(cap, currentModeResults.length));
        const itemHeight = mode === "clip" ? clipItemHeight : listItemHeight;
        return chromeHeight + n * itemHeight + (n - 1) * listSpacing;
    }

    Behavior on implicitWidth { Anim {} }
    Behavior on implicitHeight { Anim {} }

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
        // Some act, some autocomplete
        if (cmd.execute) {
            cmd.execute();
            LauncherState.open = false;
            return;
        }
        input.text = `>${cmd.name} `;
        input.cursorPosition = input.text.length;
    }

    function applyScheme(row): void {
        if (!row)
            return;
        if (row.isRandom)
            Theme.applyRandomPreset();
        else if (row.isDynamic)
            Theme.setDynamic();
        else
            Theme.applyPreset(row.id);
        LauncherState.open = false;
    }

    function applyVariant(row): void {
        if (!row)
            return;
        Config.theming.scheme = row.value;
        // Presets ignore the variant
        if (!Theme.usingPreset)
            Theme.regenerate();
        LauncherState.open = false;
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

    // Preview needs revert
    property bool hasPreviewed: false

    // Wallpaper preview lifecycle
    function previewWallpaper(entry): void {
        if (!entry)
            return;
        content.hasPreviewed = true;
        WallpaperFraming.flush();
        Quickshell.execDetached([Directories.switchwallScript, "--preview", entry.path]);
    }

    function confirmSelection(entry): void {
        applyDebounce.stop();
        content.hasPreviewed = false;
        if (entry) {
            WallpaperFraming.flush();
            Quickshell.execDetached([Directories.switchwallScript, entry.path]);
        }
        LauncherState.open = false;
    }

    function revertPreview(): void {
        applyDebounce.stop();  // cancel queued preview
        if (!content.hasPreviewed)
            return;
        content.hasPreviewed = false;
        // Real switch
        Quickshell.execDetached(["bash", "-c", `"${Directories.switchwallScript}" "$(cat "${Directories.currentWallpaperFile}")"`]);
    }

    // Activate selection
    function activateCurrent(): void {
        if (content.mode === "apps")
            content.launchApp(content.appResults[verticalList.currentIndex]);
        else if (content.mode === "commands")
            content.selectCommand(content.commandResults[verticalList.currentIndex]);
        else if (content.mode === "clip")
            content.copyClip(content.clipResults[verticalList.currentIndex]);
        else if (content.mode === "scheme")
            content.applyScheme(content.schemeResults[verticalList.currentIndex]);
        else if (content.mode === "variant")
            content.applyVariant(content.variantResults[verticalList.currentIndex]);
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

    function nudgeFraming(delta: int): void {
        const entry = content.wallpaperResults[carousel.currentIndex];
        if (!entry)
            return;
        WallpaperFraming.setFor(entry.path, WallpaperFraming.offsetFor(entry.path) + delta * 0.02);
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
        // Off-ladder on purpose
        radius: 24
        // Square bottom corners
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Colors.panel
        // No border

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

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                height: implicitHeight
                visible: content.mode === "wallpaper"

                results: content.wallpaperResults
                availableWidth: content.wallpaperPanelWidth - content.panelPad * 2

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

                model: content.mode === "wallpaper" ? [] : content.currentModeResults
                onModelChanged: currentIndex = count > 0 ? 0 : -1

                delegate: {
                    if (content.mode === "commands" || content.mode === "variant")
                        return commandItemComponent;
                    if (content.mode === "clip")
                        return clipItemComponent;
                    if (content.mode === "scheme")
                        return schemeItemComponent;
                    return appItemComponent;
                }

                // Delegate factories
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
                    id: schemeItemComponent
                    SchemeItem {
                        isCurrent: ListView.isCurrentItem
                        onActivated: content.applyScheme(modelData)
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
                text: content.emptyText
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.title
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
            color: Colors.layer

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 44
                anchors.verticalCenter: parent.verticalCenter
                text: content.placeholderText
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.title
                visible: input.text.length === 0
            }

            MaterialIcon {
                anchors.left: parent.left
                anchors.leftMargin: Motion.spacing.xlarge
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.large
            }

            // Search input
            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 44
                anchors.rightMargin: clearButton.width + Motion.spacing.large * 2
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.text
                font.pixelSize: Motion.fontSize.title
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

                // Readline key aliases
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
                Keys.onLeftPressed: event => {
                    if (content.mode !== "wallpaper")
                        event.accepted = false;
                    else if (event.modifiers & Qt.ShiftModifier)
                        content.nudgeFraming(-1);
                    else
                        content.navigateWallpaper(-1);
                }
                Keys.onRightPressed: event => {
                    if (content.mode !== "wallpaper")
                        event.accepted = false;
                    else if (event.modifiers & Qt.ShiftModifier)
                        content.nudgeFraming(1);
                    else
                        content.navigateWallpaper(1);
                }
            }

            // Clear input
            IconAction {
                id: clearButton

                anchors.right: parent.right
                anchors.rightMargin: Motion.spacing.large
                anchors.verticalCenter: parent.verticalCenter

                radius: width / 2
                iconName: "close"
                iconColor: Colors.textMuted
                iconSize: Motion.fontSize.large

                enabled: input.text.length > 0
                opacity: enabled ? 1 : 0

                Behavior on opacity { Anim { type: "effects" } }

                onTriggered: {
                    input.text = "";
                    input.forceActiveFocus();
                }
            }
        }
    }

    // Open/close sync
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

    // Edge fillets
    Corner {
        anchors { right: parent.left; bottom: parent.bottom }
        size: Motion.cornerSize
        color: Colors.panel
        corner: "bottomRight"
    }

    Corner {
        anchors { left: parent.right; bottom: parent.bottom }
        size: Motion.cornerSize
        color: Colors.panel
        corner: "bottomLeft"
    }
}

