import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"

// Screen Recorder + Recordings card (sidebar)
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    implicitHeight: column.implicitHeight + 32

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 16

        // --- Screen Recorder ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialIcon {
                text: Recorder.active ? "stop_circle" : "screen_record"
                color: Recorder.active ? "#e64553" : Colors.text
                font.pixelSize: 20
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Screen Recorder"
                    color: Colors.text
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: Recorder.active ? "Recording — " + Recorder.elapsedLabel : "Recording off"
                    color: Colors.textMuted
                    font.pixelSize: 12
                }

                // Capture mode — disabled mid-recording so it can't drift
                // from what's actually running
                RowLayout {
                    Layout.topMargin: 6
                    spacing: 6
                    enabled: !Recorder.active
                    opacity: Recorder.active ? 0.5 : 1

                    ModePill {
                        label: "Full"
                        active: Recorder.mode === "full"
                        onClicked: Recorder.mode = "full"
                    }

                    ModePill {
                        label: "Region"
                        active: Recorder.mode === "region"
                        onClicked: Recorder.mode = "region"
                    }
                }
            }

            // Start/stop toggle (same switch idiom as KeepAwakeCard)
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 40
                height: 22
                radius: height / 2
                color: Recorder.active ? Colors.primary : Colors.outline

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: width / 2
                    color: Colors.background
                    anchors.verticalCenter: parent.verticalCenter
                    x: Recorder.active ? parent.width - width - 2 : 2

                    Behavior on x { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Recorder.toggle()
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
            spacing: 8

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
                    spacing: 6

                    MaterialIcon {
                        text: "video_library"
                        color: Colors.text
                        font.pixelSize: 16
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Recordings"
                        color: Colors.text
                        font.pixelSize: 13
                    }

                    Text {
                        text: Recordings.entries.length + (Recordings.entries.length === 1 ? " recording" : " recordings")
                        color: Colors.textMuted
                        font.pixelSize: 11
                    }

                    MaterialIcon {
                        text: "expand_more"
                        color: Colors.textMuted
                        font.pixelSize: 16
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
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    visible: Recordings.entries.length === 0
                    text: "No recordings found"
                    color: Colors.textMuted
                    font.pixelSize: 12
                }

                ListView {
                    id: recordingsList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 180)
                    visible: Recordings.entries.length > 0
                    interactive: contentHeight > height
                    clip: true
                    spacing: 6

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

    // Small selectable pill for the capture-mode row
    component ModePill: Rectangle {
        id: pill

        required property string label
        property bool active: false
        signal clicked

        radius: height / 2
        color: pill.active ? Colors.primary : Colors.background
        implicitWidth: pillText.implicitWidth + 16
        implicitHeight: pillText.implicitHeight + 8

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            color: pill.active ? Colors.background : Colors.textMuted
            font.pixelSize: 10
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }
}
