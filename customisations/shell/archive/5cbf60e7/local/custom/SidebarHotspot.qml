import QtQuick

MouseArea {
    id: root

    required property var screenState

    anchors.top: parent.top
    anchors.right: parent.right
    width: 20
    height: 20
    z: 1000
    acceptedButtons: Qt.LeftButton
    onClicked: root.screenState.sidebar = !root.screenState.sidebar
}
