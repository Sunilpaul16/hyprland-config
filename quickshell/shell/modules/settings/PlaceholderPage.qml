import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Body used by every page that has no real content yet
PageBase {
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

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
            font.pixelSize: 20
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing wired up here yet."
            color: Colors.outlineVariant
            font.pixelSize: 14
        }
    }
}
