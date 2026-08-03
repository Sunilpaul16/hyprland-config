pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../services"

// Idle timeout actions, replacing hypridle's listener blocks. Its general{} block still owns the
// logind side (lock-on-LockSession, lock-before-sleep), which no idle monitor can do.
// A Scope, not a Singleton: an IdleMonitor outside the reload tree is constructed but never armed
Scope {
    id: root

    // Browsers already assert the Wayland inhibitor while playing, and respectInhibitors honours
    // that for free — this covers the players that don't, so it stays a separate opt-in
    readonly property bool mediaBlocks: Config.idle.inhibitWhenAudio && Media.isPlaying

    // Lock
    IdleMonitor {
        enabled: Config.idle.lockTimeout > 0 && !root.mediaBlocks
        timeout: Config.idle.lockTimeout
        onIsIdleChanged: {
            if (isIdle)
                Session.lock();
        }
    }

    // Displays off, back on when input returns
    IdleMonitor {
        enabled: Config.idle.dpmsTimeout > 0 && !root.mediaBlocks
        timeout: Config.idle.dpmsTimeout
        onIsIdleChanged: Hyprland.dispatch(`hl.dsp.dpms({ action = "${isIdle ? "disable" : "enable"}" })`)
    }

    // Suspend
    IdleMonitor {
        enabled: Config.idle.suspendTimeout > 0 && !root.mediaBlocks
        timeout: Config.idle.suspendTimeout
        onIsIdleChanged: {
            if (isIdle)
                Session.suspend();
        }
    }
}
