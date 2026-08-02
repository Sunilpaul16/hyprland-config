import QtQuick
import "../../services"
import "../../components"

// Read-only right-hand value for an informational row
StyledText {
    color: Colors.outline
    font.pixelSize: Motion.fontSize.subhead
    elide: Text.ElideRight
}
