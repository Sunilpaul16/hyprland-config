import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../services"
import "../../components"

// One app's volume row inside VolumeMixerDialog.qml (comparison.md #25)
RowLayout {
    id: root

    required property PwNode node

    spacing: Motion.spacing.medium

    PwObjectTracker { objects: [root.node] }

    Image {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        source: Quickshell.iconPath(root.node.properties["application.icon-name"] ?? "", "image-missing")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Motion.spacing.micro

        StyledText {
            Layout.fillWidth: true
            text: Audio.appNodeDisplayName(root.node)
            font.pixelSize: Motion.fontSize.body
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Motion.spacing.normal

            MaterialIcon {
                text: root.node.audio.muted ? "volume_off" : "volume_up"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.large

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.node.audio.muted = !root.node.audio.muted
                }
            }

            // Track + fill
            Rectangle {
                id: track
                Layout.fillWidth: true
                implicitHeight: 6
                radius: height / 2
                color: Colors.layer

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width * Math.max(0, Math.min(1, root.node.audio.volume))
                    radius: parent.radius
                    color: root.node.audio.muted ? Colors.textMuted : Colors.primary

                    Behavior on width { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onPressed: mouse => root.node.audio.volume = Math.max(0, Math.min(1, mouse.x / track.width))
                    onPositionChanged: mouse => {
                        if (pressed)
                            root.node.audio.volume = Math.max(0, Math.min(1, mouse.x / track.width));
                    }
                }
            }
        }
    }
}
