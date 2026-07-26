pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Game mode: strips Hyprland eye candy (animations, blur, shadows, gaps, rounding)
Singleton {
    id: root

    // Not mirrored into Persistent — the options live in Hyprland itself, so probeProc reads back the truth
    property bool enabled: false

    // Set while probeProc adopts the compositor's state, so that write doesn't re-apply
    property bool probing: false

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
        root.enabled = !root.enabled;
    }

    onEnabledChanged: {
        if (root.probing)
            return;
        if (root.enabled)
            root.apply();
        else
            root.restore();
    }

    // "decoration:blur:enabled" -> `eval hl.config({ decoration = { blur = { enabled = 0 } } })`
    function luaFor(key, value): string {
        const parts = key.split(":");
        return `eval hl.config({ ${parts.join(" = { ")} = ${value}${" }".repeat(parts.length - 1)} })`;
    }

    // Hyprland's non-legacy Lua parser rejects `keyword` outright ("Use eval."), hence luaFor
    function apply(): void {
        const cmds = Object.keys(root.options).map(k => root.luaFor(k, root.options[k]));
        applyProc.command = ["hyprctl", "--batch", cmds.join("; ")];
        applyProc.running = true;
    }

    // Re-reading the config files is the revert — no need to remember prior values
    function restore(): void {
        applyProc.command = ["hyprctl", "reload"];
        applyProc.running = true;
    }

    Process {
        id: applyProc
    }

    // Adopt the compositor's current state, since game mode outlives a shell restart
    Process {
        id: probeProc
        running: true
        command: ["hyprctl", "getoption", "animations:enabled", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const opt = JSON.parse(text);
                    root.probing = true;
                    root.enabled = (opt.bool === false || opt.int === 0);
                    root.probing = false;
                } catch (e) {
                    console.error("[GameMode] failed to parse hyprctl getoption:", e);
                }
            }
        }
    }

    // Any config reload restores the real config, so re-assert on top of it
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.enabled)
                root.apply();
        }
    }

    // IPC handler
    IpcHandler {
        target: "gamemode"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }

        function isEnabled(): bool {
            return root.enabled;
        }
    }
}
