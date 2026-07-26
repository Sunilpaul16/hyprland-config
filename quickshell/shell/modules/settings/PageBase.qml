import QtQuick
import "../../services"

// Page contract — large title above a content area filling the rest. Real
// pages subclass this and set `title`; children land in the body Item
Item {
    id: root

    property string title
    // Content stops widening past this and stays left-aligned under the title,
    // so a wide panel grows the margins rather than stretching every row
    readonly property int cappedWidth: Math.min(800, body.width)

    default property alias content: body.data

    Text {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.title
        color: Colors.text
        font.pixelSize: 26
        elide: Text.ElideRight
    }

    Item {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 20
    }
}
