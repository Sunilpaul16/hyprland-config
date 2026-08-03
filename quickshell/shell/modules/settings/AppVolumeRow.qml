import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../services"
import "../../components"

// App volume row
SettingRow {
    id: root

    required property PwNode node

    live: true
    label: Audio.appNodeDisplayName(root.node)

    // Track for volume
    PwObjectTracker { objects: [root.node] }

    RowLayout {
        spacing: Motion.spacing.normal

        MaterialIcon {
            text: root.node.audio.muted ? "volume_off" : "volume_up"
            color: root.node.audio.muted ? Colors.error : Colors.textMuted
            font.pixelSize: Motion.fontSize.header

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.node.audio.muted = !root.node.audio.muted
            }
        }

        NumberControl {
            value: root.node.audio.volume
            from: 0
            to: Audio.maxVolume
            stepSize: 0.01
            displayScale: 100
            suffix: "%"
            labelWidth: 46
            onMoved: v => root.node.audio.volume = v
        }
    }
}
