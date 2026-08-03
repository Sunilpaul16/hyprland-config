import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"


// Toggle pill
Rectangle {
    id: root

    required property string iconName
    property bool active: false
    property bool large: false
    property string label: ""

    signal clicked
    signal altClicked

    implicitWidth: large ? layout.implicitWidth + 24 : 40
    implicitHeight: 40
    radius: Motion.rounding.normal
    color: root.active ? Colors.primary : (hoverArea.containsMouse ? Colors.layer : Colors.panel)
    opacity: root.enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Motion.spacing.normal

        MaterialIcon {
            text: root.iconName
            color: root.active ? Colors.background : Colors.text
            font.pixelSize: Motion.fontSize.display

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        StyledText {
            visible: root.large
            text: root.label
            color: root.active ? Colors.background : Colors.text
            font.pixelSize: Motion.fontSize.label
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.altClicked();
            else
                root.clicked();
        }
    }
}
