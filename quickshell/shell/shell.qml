//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION = 10000

import QtQuick
import Quickshell
import "services"
import "modules/bar"
import "modules/dashboard"
import "modules/launcher"
import "modules/cheatsheet"
import "modules/mediaPopup"
import "modules/notifications"
import "modules/overview"
import "modules/polkit"
import "modules/screenCorners"
import "modules/session"
import "modules/settings"
import "modules/sidebarRight"
import "modules/trayMenu"
import "modules/volumeOsd"

// Shell entrypoint — each panel is its own Scope owning a per-monitor
// Variants + Config.ready-gated PanelLoader (see services/PanelLoader.qml)
ShellRoot {
    Component.onCompleted: {
        // Force ColorsLoader's lazy singleton to load and apply matugen's
        // last-written theme (see ColorsLoader.qml)
        ColorsLoader.reapplyTheme();
        // Same lazy-singleton reason: nothing else references Updates, so
        // without this its check-on-login timer never starts
        Updates.backgroundChecking = true;
    }

    Bar {}
    Launcher {}
    Cheatsheet {}
    VolumeOsd {}
    NotifPopups {}
    SessionScreen {}
    PolkitDialog {}
    MediaPopup {}
    TrayMenu {}
    SidebarRightPanel {}
    Overview {}
    DashboardPanel {}
    SettingsPanel {}
    ScreenCorners {}
}
