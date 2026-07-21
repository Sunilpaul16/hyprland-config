import QtQuick
import QtQuick.Layouts
import "../../services"


// Toggle pill button; `large` widens the pill and reveals a label (comparison.md #36)
Rectangle {
    id: root

    required property string iconName
    property bool active: false
    property bool large: false
    property string label: ""

    signal clicked

    implicitWidth: large ? layout.implicitWidth + 24 : 40
    implicitHeight: 40
    radius: 12
    color: root.active ? Colors.primary : (hoverArea.containsMouse ? Colors.surface : Colors.background)
    opacity: root.enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {
            text: root.iconName
            color: root.active ? Colors.background : Colors.text
            font.pixelSize: 20

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        Text {
            visible: root.large
            text: root.label
            color: root.active ? Colors.background : Colors.text
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
