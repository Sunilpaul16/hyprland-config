import QtQuick
import QtQuick.Layouts
import "../../services"

// Merged Keep Awake + Screen Recorder + Recordings — one shared card
// background with dividers between sections (matches caelestia's grouping,
// was three separate cards before). Static shell only — inert visuals, no
// real idle-inhibit or scripts/record wiring yet.
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
                    text: "Preventing sleep mode"
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
                        text: "Active since —"
                        color: Colors.textMuted
                        font.pixelSize: 10
                    }
                }
            }

            // Inert toggle switch (visual only — always shown "on")
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 40
                height: 22
                radius: height / 2
                color: Colors.primary

                Rectangle {
                    width: 18
                    height: 18
                    radius: width / 2
                    color: Colors.background
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width - width - 2
                }
            }
        }

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

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.outline
            opacity: 0.3
        }

        // --- Recordings ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
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

                MaterialIcon {
                    text: "expand_more"
                    color: Colors.textMuted
                    font.pixelSize: 16
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                text: "No recordings found"
                color: Colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
