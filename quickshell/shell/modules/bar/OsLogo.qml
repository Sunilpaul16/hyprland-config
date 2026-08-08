import QtQuick
import "../../services"
import "../../components"

// Distro logo
Item {
    id: root

    implicitWidth: 26
    implicitHeight: 26

    StyledText {
        anchors.centerIn: parent
        // Escapes, not literals
        text: "\uf303" // arch
        font.family: Fonts.glyphFamily
        font.pixelSize: Motion.fontSize.header
        color: hoverArea.containsMouse ? Colors.text : Colors.readable(Colors.primary)

        Behavior on color { CAnim {} }
    }

    // Opens launcher
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: LauncherState.openApps()
    }
}
