import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Section heading
StyledText {
    Layout.fillWidth: true
    Layout.topMargin: Motion.spacing.normal
    Layout.bottomMargin: -6
    color: Colors.primary
    font.pixelSize: Motion.fontSize.label
    font.weight: Font.DemiBold
    elide: Text.ElideRight
}
