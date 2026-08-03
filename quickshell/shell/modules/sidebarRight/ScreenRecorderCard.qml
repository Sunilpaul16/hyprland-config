import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// Screen Recorder + Recordings card (sidebar)
Rectangle {
    id: root

    radius: Motion.rounding.large
    color: Colors.layer
    implicitHeight: column.implicitHeight + 32

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: Motion.spacing.xlarge

        // --- Screen Recorder ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Motion.spacing.large

            MaterialIcon {
                text: Recorder.active ? "stop_circle" : "screen_record"
                color: Recorder.active ? Colors.recording : Colors.text
                font.pixelSize: Motion.fontSize.display
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Motion.spacing.micro

                RowLayout {
                    spacing: Motion.spacing.small

                    StyledText {
                        text: "Screen Recorder"
                        font.pixelSize: Motion.fontSize.subhead
                        font.bold: true
                    }

                    // Blinking REC pill (comparison.md #49) — fast fade out, slow fade back in, looping
                    Rectangle {
                        visible: Recorder.active
                        radius: height / 2
                        color: Colors.recording
                        implicitWidth: recText.implicitWidth + 10
                        implicitHeight: recText.implicitHeight + 4

                        SequentialAnimation on opacity {
                            running: Recorder.active
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.25; duration: 600; easing.type: Easing.InQuad }
                            NumberAnimation { from: 0.25; to: 1; duration: 1000; easing.type: Easing.OutQuad }
                        }

                        StyledText {
                            id: recText
                            anchors.centerIn: parent
                            text: "REC"
                            color: Colors.background
                            font.pixelSize: Motion.fontSize.micro
                            font.bold: true
                        }
                    }
                }

                StyledText {
                    text: Recorder.active ? "Recording — " + Recorder.elapsedLabel : "Recording off"
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.body
                }
            }

            // SplitButton: main segment starts/stops, chevron picks the mode (comparison.md #49)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Motion.spacing.tiny

                Rectangle {
                    id: mainSegment
                    implicitWidth: mainText.implicitWidth + 20
                    implicitHeight: 28
                    radius: height / 2
                    color: Recorder.active ? Colors.recording : Colors.primary

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    StyledText {
                        id: mainText
                        anchors.centerIn: parent
                        text: Recorder.active ? "Stop" : (Recorder.mode === "full" ? "Full" : "Region")
                        color: Colors.background
                        font.pixelSize: Motion.fontSize.body
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Recorder.toggle()
                    }
                }

                // Mode picker — hidden mid-recording so it can't drift from what's actually running
                Rectangle {
                    id: chevronSegment
                    visible: !Recorder.active
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: height / 2
                    color: chevronHover.containsMouse ? Colors.outline : Colors.background

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "expand_more"
                        color: Colors.text
                        font.pixelSize: Motion.fontSize.title
                        rotation: modeMenu.shown ? 180 : 0

                        Behavior on rotation { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                    }

                    MouseArea {
                        id: chevronHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modeMenu.shown = !modeMenu.shown
                    }
                }
            }

            RecorderModeMenu {
                id: modeMenu
                anchorItem: chevronSegment
                onItemSelected: value => {
                    Recorder.mode = value;
                    modeMenu.shown = false;
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.outline
            opacity: 0.3
        }

        // --- Recordings ---
        ColumnLayout {
            id: recordingsSection
            Layout.fillWidth: true
            spacing: Motion.spacing.normal

            property bool expanded: false
            onExpandedChanged: if (expanded) Recordings.refresh()

            // Header (click to expand/collapse)
            Item {
                Layout.fillWidth: true
                implicitHeight: headerRow.implicitHeight

                RowLayout {
                    id: headerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Motion.spacing.small

                    MaterialIcon {
                        text: "video_library"
                        color: Colors.text
                        font.pixelSize: Motion.fontSize.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Recordings"
                        font.pixelSize: Motion.fontSize.label
                    }

                    StyledText {
                        text: Recordings.entries.length + (Recordings.entries.length === 1 ? " recording" : " recordings")
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.small
                    }

                    MaterialIcon {
                        text: "expand_more"
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.large
                        rotation: recordingsSection.expanded ? 180 : 0

                        Behavior on rotation { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: recordingsSection.expanded = !recordingsSection.expanded
                }
            }

            // Expanded list
            ColumnLayout {
                Layout.fillWidth: true
                visible: recordingsSection.expanded
                spacing: Motion.spacing.small

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Motion.spacing.tiny
                    visible: Recordings.entries.length === 0
                    text: "No recordings found"
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.body
                }

                ListView {
                    id: recordingsList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 180)
                    visible: Recordings.entries.length > 0
                    interactive: contentHeight > height
                    clip: true
                    spacing: Motion.spacing.small

                    model: ScriptModel {
                        values: Recordings.entries
                    }

                    delegate: RecordingRow {
                        width: recordingsList.width
                    }
                }
            }
        }
    }

}
