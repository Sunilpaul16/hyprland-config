import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Category card
Rectangle {
    id: root

    required property string categoryName
    readonly property var rows: Binds.rowsFor(categoryName)

    property int columnWidth: 280
    property int padding: 16

    // Category name -> Material Symbol glyph
    readonly property var categoryIcons: ({
        "Window": "web_asset",
        "Workspace": "grid_view",
        "App": "apps",
        "Launcher": "rocket_launch",
        "Screenshot": "photo_camera",
        "Record": "videocam",
        "Media": "music_note",
        "System": "settings",
        "Screen": "desktop_windows"
    })
    readonly property string categoryIcon: categoryIcons[categoryName] ?? "keyboard"

    radius: Motion.rounding.normal
    color: Colors.layer
    border.width: 1
    border.color: Colors.outline

    implicitWidth: inner.implicitWidth + padding * 2
    implicitHeight: inner.implicitHeight + padding * 2

    Column {
        id: inner
        anchors.margins: root.padding
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: 10

        // Category header
        Row {
            spacing: 8

            MaterialIcon {
                text: root.categoryIcon
                color: Colors.primary
                font.pixelSize: Motion.fontSize.large
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.categoryName
                font.pixelSize: Motion.fontSize.subhead
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Header divider
        Rectangle {
            width: root.columnWidth
            height: 1
            color: Colors.outline
            opacity: 0.4
        }

        // Bind rows
        Column {
            spacing: 6

            Repeater {
                model: root.rows

                RowLayout {
                    required property var modelData
                    spacing: 12

                    KeyCombo { rowData: modelData; Layout.alignment: Qt.AlignVCenter }

                    StyledText {
                        text: modelData.label
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.body
                        Layout.preferredWidth: root.columnWidth - 130
                        wrapMode: Text.Wrap
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
