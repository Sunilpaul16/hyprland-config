pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled
    property bool initialized: false

    function setDynamicConfs(): void {
        Hypr.extras.applyOptions({
            "animations:enabled": 0,
            "decoration:shadow:enabled": 0,
            "decoration:blur:enabled": 0,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": 1
        });
    }

    function updateWallpaper(): void {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/caelestia/animated-wallpaper.py", "game-sync"]);
    }

    // Restore the session flag before scheduling playback or changing Hyprland.
    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/caelestia-wallpaper-game-mode"
        printErrors: false
        onLoaded: {
            props.enabled = true;
            root.initialized = true;
            root.setDynamicConfs();
            root.updateWallpaper();
        }
        onLoadFailed: {
            root.initialized = true;
            root.updateWallpaper();
        }
    }

    onEnabledChanged: {
        if (!initialized)
            return;
        updateWallpaper();
        if (enabled) {
            setDynamicConfs();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode enabled"), Tr.tr("Disabled Hyprland animations, blur, gaps and shadows"), "gamepad");
        } else {
            Hypr.extras.message("reload");
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode disabled"), Tr.tr("Hyprland settings restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: false

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
