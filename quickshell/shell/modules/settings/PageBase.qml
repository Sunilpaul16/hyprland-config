import QtQuick
import "../../services"
import "../../components"

// Page contract
Item {
    id: root

    property string title
    // Sub-page back arrow
    property bool isSubPage: false
    // Capped content width
    readonly property int cappedWidth: Math.min(Config.settings.maxContentWidth, body.width)
    // Space below the header
    readonly property int availableHeight: body.height

    default property alias content: body.data

    IconAction {
        id: backButton

        anchors.left: parent.left
        anchors.verticalCenter: header.verticalCenter
        visible: root.isSubPage
        implicitWidth: 32
        implicitHeight: 32
        radius: width / 2
        iconName: "arrow_back"
        iconSize: Motion.fontSize.display
        onTriggered: SettingsState.closeSubPage()
    }

    StyledText {
        id: header

        anchors.left: root.isSubPage ? backButton.right : parent.left
        anchors.leftMargin: root.isSubPage ? 12 : 0
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.title
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
