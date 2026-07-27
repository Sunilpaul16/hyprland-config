import QtQuick
import QtQuick.Layouts
import "../../services"

// Heading above a run of SettingRows
Text {
    Layout.fillWidth: true
    Layout.topMargin: 8
    Layout.bottomMargin: -6
    color: Colors.primary
    font.pixelSize: 13
    font.weight: Font.DemiBold
    elide: Text.ElideRight
}
