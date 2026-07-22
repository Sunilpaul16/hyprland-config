pragma Singleton
import QtQuick
import Quickshell

// Centralizes $HOME-rooted paths scattered across services/ and modules/
QtObject {
    readonly property string home: Quickshell.env("HOME")

    readonly property string configFile: home + "/.config/quickshell/config.json"
    readonly property string colorsFile: home + "/.local/state/quickshell/colors.json"
    readonly property string stateFile: home + "/.local/state/quickshell/state.json"
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
    readonly property string bongocatGif: home + "/hyprland-config/assets/bongocat.gif"
}
