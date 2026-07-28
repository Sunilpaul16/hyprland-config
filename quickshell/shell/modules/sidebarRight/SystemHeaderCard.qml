import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// System header (sidebar) — distro logo + uptime on the left, action icons on
// the right: restart the shell, open settings, open the session screen.
Rectangle {
    id: root

    radius: 18
    color: Colors.layer
    implicitHeight: content.implicitHeight + 24

    RowLayout {
        id: content

        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
        spacing: 8

        Text {
            text: SysInfo.osGlyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: Colors.text
        }

        Text {
            Layout.fillWidth: true
            text: `Uptime: ${SysInfo.uptimeShort}`
            color: Colors.text
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        // Restart the shell — same command as SUPER + CTRL + R
        IconAction {
            iconName: "refresh"
            iconColor: Colors.textMuted
            onTriggered: Quickshell.execDetached(["bash", "-c", "pkill -x qs; qs -n -c shell"])
        }

        IconAction {
            iconName: "settings"
            iconColor: Colors.textMuted
            onTriggered: SettingsState.toggle()
        }

        IconAction {
            iconName: "power_settings_new"
            iconColor: Colors.textMuted
            onTriggered: SessionState.open = true
        }
    }
}
