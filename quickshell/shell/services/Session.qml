pragma Singleton
import QtQuick
import Quickshell

// Session/power actions in one place, so the drawer's buttons and any caller share one definition
Singleton {
    id: root

    // Graceful first: hyprshutdown tidies clients up, Hyprland's own exit is the fallback, and
    // terminate-session is the last resort if the compositor is already unresponsive
    readonly property var logoutCommand: ["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()' || loginctl terminate-session \"${XDG_SESSION_ID:-self}\""]

    readonly property var lockCommand: ["bash", "-c", "hyprlock || loginctl lock-session \"${XDG_SESSION_ID:-}\""]

    // systemctl only, deliberately. Modern loginctl (systemd 261 here) has no poweroff/reboot verb —
    // only session ones — and /usr/bin/poweroff is a symlink to systemctl, so there is no second
    // implementation to fall back to. Don't "fix" this by adding a loginctl chain; it would just fail louder.
    readonly property var poweroffCommand: ["systemctl", "poweroff"]
    readonly property var rebootCommand: ["systemctl", "reboot"]

    function lock(): void {
        Quickshell.execDetached(root.lockCommand);
    }

    function logout(): void {
        Quickshell.execDetached(root.logoutCommand);
    }

    function poweroff(): void {
        Quickshell.execDetached(root.poweroffCommand);
    }

    function reboot(): void {
        Quickshell.execDetached(root.rebootCommand);
    }
}
