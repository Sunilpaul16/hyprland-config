import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Placeholder body
PageBase {
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Motion.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "handyman"
            color: Colors.outlineVariant
            font.pixelSize: 56
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Page under construction"
            color: Colors.outlineVariant
            font.pixelSize: Motion.fontSize.display
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing wired up here yet."
            color: Colors.outlineVariant
            font.pixelSize: Motion.fontSize.subhead
        }
    }
}
