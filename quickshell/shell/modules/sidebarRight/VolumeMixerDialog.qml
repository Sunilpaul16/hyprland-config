import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Per-app volume mixer, overlaid on the sidebar's card stack (comparison.md #25)
Rectangle {
    id: root

    radius: Motion.rounding.drawer
    color: Colors.panel

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Motion.spacing.xlarge
        spacing: Motion.spacing.large

        // Header
        RowLayout {
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
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: sections.implicitHeight
            clip: true

            ColumnLayout {
                id: sections
                width: parent.width
                spacing: Motion.spacing.xlarge

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
                    Layout.topMargin: Motion.spacing.section
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
