import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// System header card
Rectangle {
    id: root

    radius: Motion.rounding.large
    color: Colors.layer
    implicitHeight: content.implicitHeight + 24

    RowLayout {
        id: content

        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
        spacing: Motion.spacing.normal

        StyledText {
            text: SysInfo.osGlyph
            font.family: Fonts.glyphFamily
            font.pixelSize: Motion.fontSize.large
        }

        StyledText {
            Layout.fillWidth: true
            text: `Uptime: ${SysInfo.uptimeShort}`
            color: Colors.text
            font.pixelSize: Motion.fontSize.label
            elide: Text.ElideRight
        }

        // Restart shell
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
