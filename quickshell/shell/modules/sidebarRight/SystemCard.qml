import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"


// System card (Keep Awake / Screen Recorder / Recordings)
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    implicitHeight: column.implicitHeight + 32

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 16

        // --- Keep Awake ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialIcon {
                text: "coffee"
                color: Colors.text
                font.pixelSize: 20
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Keep Awake"
                    color: Colors.text
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: IdleInhibitState.enabled ? "Preventing sleep mode" : "Sleep as normal"
                    color: Colors.textMuted
                    font.pixelSize: 12
                }

                Rectangle {
                    Layout.topMargin: 6
                    radius: 8
                    color: Colors.background
                    implicitWidth: activeSinceText.implicitWidth + 16
                    implicitHeight: activeSinceText.implicitHeight + 6

                    Text {
                        id: activeSinceText
                        anchors.centerIn: parent
                        text: IdleInhibitState.enabled
                            ? "Active since " + Qt.formatDateTime(new Date(IdleInhibitState.activeSince), "hh:mm")
                            : "Active since —"
                        color: Colors.textMuted
                        font.pixelSize: 10
                    }
                }
            }

            // Keep Awake toggle switch
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 40
                height: 22
                radius: height / 2
                color: IdleInhibitState.enabled ? Colors.primary : Colors.outline

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: width / 2
                    color: Colors.background
                    anchors.verticalCenter: parent.verticalCenter
                    x: IdleInhibitState.enabled ? parent.width - width - 2 : 2

                    Behavior on x { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IdleInhibitState.toggle()
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

        // --- Screen Recorder ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialIcon {
                text: "screen_record"
                color: Colors.text
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
                    text: "Recording off"
                    color: Colors.textMuted
                    font.pixelSize: 12
                }
            }

            Rectangle {
                radius: 8
                color: Colors.background
                implicitWidth: fullscreenRow.implicitWidth + 20
                implicitHeight: fullscreenRow.implicitHeight + 10

                RowLayout {
                    id: fullscreenRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Fullscreen"
                        color: Colors.text
                        font.pixelSize: 11
                    }

                    MaterialIcon {
                        text: "expand_more"
                        color: Colors.textMuted
                        font.pixelSize: 16
                    }
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
}
