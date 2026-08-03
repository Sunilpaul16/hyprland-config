import QtQuick
import "../../services"
import "../../components"

// Read-only value
StyledText {
    color: Colors.outline
    font.pixelSize: Motion.fontSize.subhead
    elide: Text.ElideRight
}
