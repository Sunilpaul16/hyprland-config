import QtQuick
import "../../services"
import "../../components"

// Read-only right-hand value for an informational row
StyledText {
    color: Colors.outline
    font.pixelSize: 14
    elide: Text.ElideRight
}
