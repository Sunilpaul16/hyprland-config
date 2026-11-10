import QtQuick
import Quickshell
import Caelestia.Config

Scope {
    id: root

    required property var gameMode

    readonly property string pickerDir: Quickshell.env("HOME") + "/.cache/caelestia/video-picker"

    readonly property bool videoPlaybackEnabled: gameMode.initialized && !GlobalConfig.forScreen("eDP-1").background.wallpaperEnabled && !gameMode.enabled
    onVideoPlaybackEnabledChanged: playbackSync.restart()
    Component.onCompleted: playbackSync.restart()

    Timer {
        id: playbackSync
        interval: 200
        onTriggered: Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/caelestia/animated-wallpaper.py", "playback-sync"])
    }

    function setRandom(): void {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/caelestia/animated-wallpaper.py", "random"]);
    }

    function setWallpaper(path: string): void {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/caelestia/animated-wallpaper.py", "set", path]);
    }
}
