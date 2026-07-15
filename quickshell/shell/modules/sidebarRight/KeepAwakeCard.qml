import QtQuick
import QtQuick.Layouts
import "../../services"

// Static shell only — the toggle/pill are inert visuals, no real
// idle-inhibit wiring yet (would need a services/KeepAwake.qml singleton
// around systemd-inhibit or hypridle, same pattern as Audio.qml/Media.qml).
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    implicitHeight: row.implicitHeight + 32

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        Text {
            text: "\u{2615}" // hot beverage glyph, matches "keep awake" concept
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
}
