import QtQuick
import "../../services"
import "../sidebarRight"

// Session/power actions column — right-edge drawer content
Column {
    id: root

    spacing: 16

    // Focus the first action button — called once from SessionScreen.qml
    // when the drawer opens, so Up/Down/Enter work without a click first
    function focusFirst(): void {
        logoutBtn.forceActiveFocus();
    }

    SessionActionButton {
        id: logoutBtn
        icon: "logout"
        command: ["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]
        warnIfBusy: true
        KeyNavigation.down: poweroffBtn
    }

    SessionActionButton {
        id: poweroffBtn
        icon: "power_settings_new"
        command: ["systemctl", "poweroff"]
        warnIfBusy: true
        KeyNavigation.up: logoutBtn
        KeyNavigation.down: lockBtn
    }

    // Decorative slot — no gif asset yet, spins an icon in its place
    Item {
        implicitWidth: 64
        implicitHeight: 64

        MaterialIcon {
            anchors.centerIn: parent
            text: "sync"
            color: Colors.textMuted
            font.pixelSize: 28

            RotationAnimation on rotation {
                running: parent.visible
                from: 0
                to: 360
                duration: 1400
                loops: Animation.Infinite
            }
        }
    }

    SessionActionButton {
        id: lockBtn
        icon: "lock"
        command: ["hyprlock"]
        KeyNavigation.up: poweroffBtn
        KeyNavigation.down: rebootBtn
    }

    SessionActionButton {
        id: rebootBtn
        icon: "cached"
        command: ["systemctl", "reboot"]
        warnIfBusy: true
        KeyNavigation.up: lockBtn
    }
}
