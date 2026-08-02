import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Heading above a run of SettingRows
StyledText {
    Layout.fillWidth: true
    Layout.topMargin: 8
    Layout.bottomMargin: -6
    color: Colors.primary
    font.pixelSize: Motion.fontSize.label
    font.weight: Font.DemiBold
    elide: Text.ElideRight
}
