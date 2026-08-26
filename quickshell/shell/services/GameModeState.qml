pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Game mode
Singleton {
    id: root

    // Restored across a Quickshell restart, but never carried into a new login.
    property bool enabled: !Persistent.isNewHyprlandInstance && Persistent.gameModeEnabled
    property real activeSince: 0

    readonly property var options: ({
        "animations:enabled": 0,
        "decoration:shadow:enabled": 0,
        "decoration:blur:enabled": 0,
        "general:gaps_in": 0,
        "general:gaps_out": 0,
        "general:border_size": 1,
        "decoration:rounding": 0,
        "general:allow_tearing": 1
    })

    function toggle(): void {
        root.setEnabled(!root.enabled, true);
    }

    function setEnabled(on: bool, announce: bool): void {
        if (root.enabled === on)
            return;

        if (on) {
            // Remember companion-toggle state so disabling game mode is lossless.
            Persistent.gameModeDndWasEnabled = DndState.enabled;
            Persistent.gameModeIdleInhibitWasEnabled = IdleInhibitState.enabled;
            root.enabled = true;
            root.activeSince = Date.now();
            root.apply();
            DndState.enabled = true;
            IdleInhibitState.enabled = true;
        } else {
            root.enabled = false;
            root.activeSince = 0;
            root.restore();
            DndState.enabled = Persistent.gameModeDndWasEnabled;
            IdleInhibitState.enabled = Persistent.gameModeIdleInhibitWasEnabled;
        }

        Persistent.gameModeEnabled = root.enabled;
        if (announce)
            Notifs.toast(root.enabled ? "Game mode on" : "Game mode off", root.enabled ? "Visual effects paused, notifications muted and idle inhibited" : "Desktop and notification settings restored", "sports_esports");
    }

    // Key to Lua eval
    function luaFor(key, value): string {
        const parts = key.split(":");
        return `eval hl.config({ ${parts.join(" = { ")} = ${value}${" }".repeat(parts.length - 1)} })`;
    }

    // Apply overrides
    function apply(): void {
        const cmds = Object.keys(root.options).map(k => root.luaFor(k, root.options[k]));
        applyProc.command = ["hyprctl", "--batch", cmds.join("; ")];
        applyProc.running = true;
        root.setWallpaperPaused(true);
    }

    // Restore by reload
    function restore(): void {
        applyProc.command = ["hyprctl", "reload"];
        applyProc.running = true;
        root.setWallpaperPaused(false);
    }

    // Freeze video wallpaper
    function setWallpaperPaused(paused: bool): void {
        WallpaperMpv.command(["set_property", "pause", paused]);
    }

    Process {
        id: applyProc
    }

    function applyRestoredState(): void {
        if (root.enabled && root.activeSince === 0) {
            root.activeSince = Date.now();
            root.apply();
            DndState.enabled = true;
            IdleInhibitState.enabled = true;
        }
    }

    // Re-apply state restored after a Quickshell restart. Persistent state may
    // finish loading either before or after this singleton is constructed.
    Component.onCompleted: root.applyRestoredState()

    Connections {
        target: Persistent
        function onIsNewHyprlandInstanceChanged(): void {
            root.applyRestoredState();
        }
    }

    // Re-assert after reload
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.enabled)
                root.apply();
        }
    }

    // Re-assert after mpvpaper restart
    Connections {
        target: WallpaperMpv
        function onSocketConnected(monitor) {
            if (root.enabled)
                WallpaperMpv.commandTo(monitor, ["set_property", "pause", true]);
        }
    }

    // IPC handler
    IpcHandler {
        target: "gamemode"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.setEnabled(true, true);
        }

        function disable(): void {
            root.setEnabled(false, true);
        }

        function isEnabled(): bool {
            return root.enabled;
        }

        function status(): string {
            return `enabled=${root.enabled} activeSince=${Math.round(root.activeSince)} dnd=${DndState.enabled} idleInhibit=${IdleInhibitState.enabled}`;
        }
    }
}
