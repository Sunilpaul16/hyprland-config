import QtQuick
import "../../services"
import "../sidebarRight"

// Page contract — large title above a content area filling the rest. Real
// pages subclass this and set `title`; children land in the body Item
Item {
    id: root

    property string title
    // Sub-pages get a back arrow ahead of the title
    property bool isSubPage: false
    // Content stops widening past this and stays left-aligned under the title,
    // so a wide panel grows the margins rather than stretching every row
    readonly property int cappedWidth: Math.min(800, body.width)

    default property alias content: body.data

    Rectangle {
        id: backButton

        anchors.left: parent.left
        anchors.verticalCenter: header.verticalCenter
        visible: root.isSubPage
        width: 32
        height: 32
        radius: width / 2
        color: backHover.containsMouse ? Colors.surface : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            anchors.centerIn: parent
            text: "arrow_back"
            color: Colors.text
            font.pixelSize: 20
        }

        MouseArea {
            id: backHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SettingsState.closeSubPage()
        }
    }

    Text {
        id: header

        anchors.left: root.isSubPage ? backButton.right : parent.left
        anchors.leftMargin: root.isSubPage ? 12 : 0
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
