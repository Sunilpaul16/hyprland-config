pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reads matugen's colors.json and mutates Colors's properties in place, so a wallpaper change cross-fades instead of restarting the shell
// Singletons are lazy — shell.qml's Component.onCompleted must call reapplyTheme() once or this never loads
Singleton {
    id: root

    // True while a candidate palette is on screen instead of the real one
    property bool previewing: false
    property string previewPath: ""
    // Latest request while a generation is already running; matugen takes a
    // second or two, and a hover sweep would otherwise queue one per tile
    property string pendingPath: ""

    // Generates a palette for `path` and swaps it into Colors only — wallpaper, colors.json and every other themed app are untouched, so clearPreview() fully reverts
    function preview(path: string): void {
        if (!path || path === root.previewPath)
            return;
        if (previewProc.running) {
            root.pendingPath = path;
            return;
        }
        root.previewPath = path;
        previewProc.command = [Directories.switchwallScript, "--colors-preview", path];
        previewProc.running = true;
    }

    function clearPreview(): void {
        root.pendingPath = "";
        root.previewPath = "";
        if (!root.previewing)
            return;
        root.previewing = false;
        root.reapplyTheme();
    }

    // A preset's colours are already on disk, so unlike preview() there's nothing to generate — maps template role names onto the shell's own and reuses the revert path
    function previewPalette(palette: var): void {
        if (!palette || !palette.primary)
            return;
        root.previewPath = "";
        root.pendingPath = "";
        root.previewing = true;
        root.applyColors(JSON.stringify({
            background: palette.background,
            surface: palette.surface_container,
            primary: palette.primary,
            secondary: palette.secondary,
            tertiary: palette.tertiary,
            textOnPrimary: palette.on_primary,
            secondaryContainer: palette.secondary_container,
            text: palette.on_surface,
            textMuted: palette.on_surface_variant,
            outline: palette.outline,
            outlineVariant: palette.outline_variant,
            error: palette.error,
            textOnError: palette.on_error,
            errorContainer: palette.error_container
        }));
    }

    function reapplyTheme() {
        colorsFile.reload();
        applyTimer.restart();
    }

    function applyColors(text) {
        if (!text)
            return;

        let json;
        try {
            json = JSON.parse(text);
        } catch (e) {
            return;
        }

        for (const key in json) {
            if (Colors.hasOwnProperty(key))
                Colors[key] = json[key];
        }
    }

    function applyPreview(text: string): void {
        if (!root.previewPath)
            return;
        root.previewing = true;
        root.applyColors(text);
    }

    // onLoadedChanged fires only on the loaded/not-loaded transition, so later re-reads go through this debounced timer and apply reload()'d text() directly
    Timer {
        id: applyTimer
        interval: 50
        repeat: false
        onTriggered: root.applyColors(colorsFile.text())
    }

    Process {
        id: previewProc

        onExited: exitCode => {
            const next = root.pendingPath;
            root.pendingPath = "";
            if (exitCode === 0 && root.previewPath) {
                previewFile.reload();
                previewApplyTimer.restart();
            }
            // A newer hover landed while this was generating
            if (next && next !== root.previewPath) {
                root.previewPath = "";
                root.preview(next);
            }
        }
    }

    // Same reload() caveat as colorsFile below — onLoadedChanged does not
    // fire again once loaded, so re-reads go through this timer
    Timer {
        id: previewApplyTimer
        interval: 50
        repeat: false
        onTriggered: root.applyPreview(previewFile.text())
    }

    FileView {
        id: previewFile

        path: Directories.previewColorsFile

        onLoadedChanged: {
            if (loaded && root.previewPath)
                root.applyPreview(text());
        }
    }

    FileView {
        id: colorsFile
        path: Directories.colorsFile
        watchChanges: true

        onFileChanged: root.reapplyTheme()
        onLoadedChanged: root.applyColors(text())
    }
}
