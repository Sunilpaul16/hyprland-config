//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION = 10000

import QtQuick
import Quickshell
import "services"
import "modules/bar"
import "modules/dashboard"
import "modules/launcher"
import "modules/cheatsheet"
import "modules/idle"
import "modules/notifications"
import "modules/overlay"
import "modules/overview"
import "modules/polkit"
import "modules/screenCorners"
import "modules/session"
import "modules/settings"
import "modules/sidebarRight"
import "modules/trayMenu"
import "modules/volumeOsd"

// Shell entrypoint
ShellRoot {
    Component.onCompleted: {
        // Wake lazy singletons
        ColorsLoader.reapplyTheme();
        Updates.backgroundChecking = true;
        NightLightState.scheduling = true;
    }

    Bar {}
    Launcher {}
    Cheatsheet {}
    VolumeOsd {}
    NotifPopups {}
    SessionScreen {}
    PolkitDialog {}
    TrayMenu {}
    SidebarRightPanel {}
    Overview {}
    Overlay {}
    DashboardPanel {}
    SettingsPanel {}
    ScreenCorners {}
    IdleMonitors {}
}
