import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../services"
import "../../components"

// One application's volume, as a settings row. The sidebar's
// VolumeMixerEntry does the same job in its own layout; this shares the
// service, not the presentation
SettingRow {
    id: root

    required property PwNode node

    live: true
    label: Audio.appNodeDisplayName(root.node)

    // An untracked node reports no volume at all, so the row would read 0%
    PwObjectTracker { objects: [root.node] }

    RowLayout {
        spacing: 8

        MaterialIcon {
            text: root.node.audio.muted ? "volume_off" : "volume_up"
            color: root.node.audio.muted ? Colors.error : Colors.textMuted
            font.pixelSize: 18

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
