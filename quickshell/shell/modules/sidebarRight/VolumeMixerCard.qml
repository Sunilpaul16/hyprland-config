import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Volume mixer card
Rectangle {
    id: root

    readonly property bool expanded: SidebarDialogState.mixerOpen
    readonly property int maxHeight: 320
    // Chrome around the list
    readonly property int chrome: header.implicitHeight + Motion.spacing.large + 32
    readonly property int naturalHeight: root.chrome + sections.implicitHeight

    radius: Motion.rounding.large
    color: Colors.layer
    border.width: 1
    border.color: Colors.outlineVariant
    clip: true

    implicitHeight: root.expanded ? Math.min(root.naturalHeight, root.maxHeight) : 0
    opacity: root.expanded ? 1 : 0
    // Drops its layout spacing
    visible: root.expanded || root.implicitHeight > 0

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    Behavior on opacity {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Motion.spacing.xlarge }
        spacing: Motion.spacing.large

        // Header
        RowLayout {
            id: header

            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: "Volume Mixer"
                font.pixelSize: Motion.fontSize.title
                font.bold: true
            }

            IconAction {
                iconName: "close"
                onTriggered: SidebarDialogState.close()
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(sections.implicitHeight, root.maxHeight - root.chrome)
            contentWidth: width
            contentHeight: sections.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: sections

                width: parent.width
                spacing: Motion.spacing.xlarge

                // Playback streams
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Motion.spacing.medium
                    visible: Audio.outputAppNodes.length > 0

                    StyledText { text: "Playing"; color: Colors.textMuted; font.pixelSize: Motion.fontSize.small }

                    Repeater {
                        model: Audio.outputAppNodes
                        delegate: VolumeMixerEntry {
                            required property var modelData
                            Layout.fillWidth: true
                            node: modelData
                        }
                    }
                }

                // Capture streams
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Motion.spacing.medium
                    visible: Audio.inputAppNodes.length > 0

                    StyledText { text: "Recording"; color: Colors.textMuted; font.pixelSize: Motion.fontSize.small }

                    Repeater {
                        model: Audio.inputAppNodes
                        delegate: VolumeMixerEntry {
                            required property var modelData
                            Layout.fillWidth: true
                            node: modelData
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: Audio.outputAppNodes.length === 0 && Audio.inputAppNodes.length === 0
                    text: "No apps are using audio right now"
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.label
                }
            }
        }
    }
}
