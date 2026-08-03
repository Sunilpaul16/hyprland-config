import QtQuick
import QtQuick.Layouts
import "../../services"

// Scrolling page contract
PageBase {
    id: root

    default property alias stack: column.data

    content: Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight + 24
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: column

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: root.cappedWidth
            spacing: Motion.spacing.wide
        }
    }
}
