import QtQuick
import QtQuick.Layouts
import "../../services"

// Per-app volume mixer, overlaid on the sidebar's card stack (comparison.md #25)
Rectangle {
    id: root

    radius: 20
    color: Colors.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Volume Mixer"
                color: Colors.text
                font.pixelSize: 15
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
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: Audio.outputAppNodes.length > 0

                    Text { text: "Playing"; color: Colors.textMuted; font.pixelSize: 11 }

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
                    spacing: 10
                    visible: Audio.inputAppNodes.length > 0

                    Text { text: "Recording"; color: Colors.textMuted; font.pixelSize: 11 }

                    Repeater {
                        model: Audio.inputAppNodes
                        delegate: VolumeMixerEntry {
                            required property var modelData
                            Layout.fillWidth: true
                            node: modelData
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    visible: Audio.outputAppNodes.length === 0 && Audio.inputAppNodes.length === 0
                    text: "No apps are using audio right now"
                    color: Colors.textMuted
                    font.pixelSize: 13
                }
            }
        }
    }
}
