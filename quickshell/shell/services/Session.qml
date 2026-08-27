pragma Singleton
import QtQuick
import Quickshell

// Session actions
Singleton {
    id: root

    // Logout chain
    readonly property var logoutCommand: ["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()' || loginctl terminate-session \"${XDG_SESSION_ID:-self}\""]

    readonly property var lockCommand: ["bash", "-c", "hyprlock || loginctl lock-session \"${XDG_SESSION_ID:-}\""]

    // Let applications (especially browsers) save clean exit state before the
    // session disappears, then perform the requested system action.
    readonly property var poweroffCommand: ["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown --post-cmd 'systemctl poweroff' || systemctl poweroff"]
    readonly property var rebootCommand: ["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown --post-cmd 'systemctl reboot' || systemctl reboot"]
    // systemctl only
    readonly property var suspendCommand: ["systemctl", "suspend"]

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

    function suspend(): void {
        Quickshell.execDetached(root.suspendCommand);
    }
}
