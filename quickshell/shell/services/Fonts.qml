pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


// Font resolution
Singleton {
    id: root

    // Installed families
    readonly property var installed: Qt.fontFamilies()

    // Resolved families
    readonly property string desktopInterfaceFamily: root.resolve(Config.appearance.fontInterface, "Adwaita Sans")
    readonly property string interfaceFamily: Config.appearance.shellFollowSystemFont
        ? root.desktopInterfaceFamily : root.resolve("Noto Sans", "Adwaita Sans")
    readonly property string glyphFamily: root.resolve(Config.appearance.fontGlyph, "JetBrainsMono Nerd Font")

    readonly property string monospaceFamily: root.resolve(Config.appearance.fontMonospace, "Adwaita Mono")
    readonly property var monospaceOptions: ["Adwaita Mono", "Noto Sans Mono", "JetBrainsMono Nerd Font", "DejaVu Sans Mono", "Liberation Mono"]
        .filter(f => root.installed.indexOf(f) !== -1).map(f => ({ value: f, label: f }))

    function applySystem(): void {
        if (Config.ready && Config.fileValid)
            applyTimer.restart();
    }

    Connections {
        target: Config.appearance
        function onFontInterfaceChanged(): void { root.applySystem(); }
        function onFontMonospaceChanged(): void { root.applySystem(); }
        function onFontSizeChanged(): void { root.applySystem(); }
    }
    Connections {
        target: Config
        function onReadyChanged(): void { root.applySystem(); }
    }
    Component.onCompleted: root.applySystem()
    Timer {
        id: applyTimer
        interval: 300
        onTriggered: {
            if (applyProcess.running) { restart(); return; }
            applyProcess.command = ["python3", Directories.repoRoot + "/scripts/apply-system-fonts.py",
                root.desktopInterfaceFamily, root.monospaceFamily, String(Config.appearance.fontSize)];
            applyProcess.running = true;
        }
    }
    Process {
        id: applyProcess
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("[Fonts] Could not apply desktop fonts:", stderr.text);
        }
    }

    // Interface options
    readonly property var interfaceOptions: [
        "Noto Sans",
        "Rubik",
        "Adwaita Sans",
        "Open Sans",
        "Space Grotesk",
        "Readex Pro",
        "Carlito",
        "DejaVu Sans",
        "Liberation Sans",
        "VT323"
    ].filter(f => root.installed.indexOf(f) !== -1).map(f => ({ value: f, label: f }))

    // Glyph options
    readonly property var glyphOptions: root.installed
        .filter(f => /Nerd Font$/.test(f))
        .map(f => ({ value: f, label: f }))

    function resolve(want: string, fallback: string): string {
        if (want && root.installed.indexOf(want) !== -1)
            return want;
        return fallback;
    }
}
