import QtQuick
import "../../services"
import "../sidebarRight"

// Session/power actions column — right-edge drawer content
Column {
    id: root

    spacing: 16

    SessionActionButton {
        icon: "logout"
        command: ["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]
    }

    SessionActionButton {
        icon: "power_settings_new"
        command: ["systemctl", "poweroff"]
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
        icon: "lock"
        command: ["hyprlock"]
    }

    SessionActionButton {
        icon: "cached"
        command: ["systemctl", "reboot"]
    }
}
