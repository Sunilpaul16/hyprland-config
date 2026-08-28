pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../services"

// Idle timeout actions
Scope {
    id: root

    // Media inhibit
    readonly property bool mediaBlocks: Config.idle.inhibitWhenAudio && Media.isPlaying

    // Lock
    IdleMonitor {
        enabled: Config.idle.lockTimeout > 0 && !root.mediaBlocks && !IdleInhibitState.enabled
        timeout: Config.idle.lockTimeout
        onIsIdleChanged: {
            if (isIdle)
                Session.lock();
        }
    }

    // Displays off
    IdleMonitor {
        enabled: Config.idle.dpmsTimeout > 0 && !root.mediaBlocks && !IdleInhibitState.enabled
        timeout: Config.idle.dpmsTimeout
        onIsIdleChanged: Hyprland.dispatch(`hl.dsp.dpms({ action = "${isIdle ? "disable" : "enable"}" })`)
    }

    // Suspend
    IdleMonitor {
        enabled: Config.idle.suspendTimeout > 0 && !root.mediaBlocks && !IdleInhibitState.enabled
        timeout: Config.idle.suspendTimeout
        onIsIdleChanged: {
            if (isIdle)
                Session.suspend();
        }
    }
}
