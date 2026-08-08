pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Applies matugen palette
Singleton {
    id: root

    // Preview active
    property bool previewing: false
    property string previewPath: ""
    // Queued preview path
    property string pendingPath: ""

    // Wallpaper brightness
    property FileView luminanceFile: FileView {
        path: Directories.wallpaperLuminanceFile
        watchChanges: true

        onLoaded: {
            const value = parseFloat(text().trim());
            Colors.wallLuminance = isNaN(value) ? 0 : Math.max(0, Math.min(1, value));
        }
        onFileChanged: reload()
    }

    // Preview from image
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

    // Preview from preset
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

        root.harmonise(json);
    }

    // Guard generated roles
    function harmonise(json): void {
        // Read the incoming values; the properties are still animating
        const text = json.text ? Qt.color(json.text) : Colors.text;
        const bg = json.background ? Qt.color(json.background) : Colors.background;
        const err = json.error ? Qt.color(json.error) : Colors.error;
        const prim = json.primary ? Qt.color(json.primary) : Colors.primary;

        // Generators put muted text far too close to body text
        Colors.textMuted = Qt.rgba(text.r + (bg.r - text.r) * 0.28, text.g + (bg.g - text.g) * 0.28, text.b + (bg.b - text.b) * 0.28, 1);

        // A red wallpaper can collapse error onto primary
        if (Colors.distance(err, prim) < 0.25)
            Colors.error = Qt.hsla(err.hslHue, 0.85, 0.45, 1);
    }

    function applyPreview(text: string): void {
        if (!root.previewPath)
            return;
        root.previewing = true;
        root.applyColors(text);
    }

    // Debounced re-read
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
            // Newer request queued
            if (next && next !== root.previewPath) {
                root.previewPath = "";
                root.preview(next);
            }
        }
    }

    // Debounced re-read
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
