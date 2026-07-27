pragma Singleton
import QtQuick
import Quickshell

// Centralizes $HOME-rooted paths scattered across services/ and modules/
QtObject {
    readonly property string home: Quickshell.env("HOME")

    readonly property string configFile: home + "/.config/quickshell/config.json"
    readonly property string colorsFile: home + "/.local/state/quickshell/colors.json"
    readonly property string previewColorsFile: home + "/.cache/matugen/preview-colors.json"
    readonly property string stateFile: home + "/.local/state/quickshell/state.json"
    readonly property string colorModeFile: home + "/.local/state/quickshell/color_mode"
    readonly property string notificationsFile: home + "/.local/state/quickshell/notifications.json"

    readonly property string localBin: home + "/.local/bin"
    readonly property string recordScript: localBin + "/record"
    readonly property string switchwallScript: localBin + "/switchwall"

    readonly property string wallpaperDir: home + "/wallpaper"
    readonly property string wallpaperThumbCache: home + "/.cache/wallpaper-thumbs"
    readonly property string currentWallpaperFile: home + "/.local/state/quickshell/current_wallpaper"
    readonly property string mediaArtCache: home + "/.cache/quickshell-media-art"
    readonly property string videosDir: home + "/Videos"
    readonly property string faceIcon: home + "/.face"
    readonly property string repoRoot: home + "/hyprland-config"
    readonly property string bongocatGif: repoRoot + "/assets/bongocat.gif"
    readonly property string dinoImage: repoRoot + "/assets/dino.png"

    // Expands a config-supplied path: absolute and ~-rooted pass through, anything else is repo-relative
    function resolve(path: string): string {
        if (!path)
            return "";
        if (path.startsWith("/"))
            return path;
        if (path.startsWith("~/"))
            return home + path.slice(1);
        return repoRoot + "/" + path.replace(/^\.\//, "");
    }
}
