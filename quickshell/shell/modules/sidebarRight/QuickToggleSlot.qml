import QtQuick
import "../../services"
import "quickToggles"
import "../../components"

// Toggle slot
Item {
    id: slot

    required property QuickToggleModel toggleModel
    required property string size // "small" | "large"
    property bool editMode: false
    property bool isFirst: false
    property bool isLast: false

    signal resizeRequested()
    signal hideRequested()
    signal moveRequested(delta: int)

    readonly property bool large: slot.size === "large"

    implicitWidth: pill.implicitWidth
    implicitHeight: 40

    TogglePill {
        id: pill
        anchors.fill: parent
        iconName: slot.toggleModel.icon
        active: slot.toggleModel.toggled
        enabled: slot.toggleModel.available && !slot.editMode
        large: slot.large
        label: slot.toggleModel.name
        onClicked: slot.toggleModel.mainAction()
        onAltClicked: if (slot.toggleModel.altAction) slot.toggleModel.altAction()
    }

    // Edit-mode controls
    MouseArea {
        anchors.fill: parent
        enabled: slot.editMode
        cursorShape: Qt.PointingHandCursor
        onClicked: slot.resizeRequested()

        Rectangle {
            anchors.fill: parent
            radius: Motion.rounding.normal
            color: "transparent"
            border.width: 1
            border.color: Colors.outline
        }
    }

    // Hide badge
    Rectangle {
        visible: slot.editMode
        width: 14
        height: 14
        radius: width / 2
        anchors { top: parent.top; right: parent.right; margins: -2 }
        color: Colors.outline
        border.color: Colors.surface
        border.width: 1.5

        MaterialIcon {
            anchors.centerIn: parent
            text: "close"
            color: Colors.background
            font.pixelSize: Motion.fontSize.micro
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: slot.hideRequested()
        }
    }

    // Move earlier badge
    Rectangle {
        visible: slot.editMode && !slot.isFirst
        width: 14
        height: 14
        radius: width / 2
        anchors { bottom: parent.bottom; left: parent.left; margins: -2 }
        color: Colors.layer
        border.color: Colors.outline
        border.width: 1

        MaterialIcon {
            anchors.centerIn: parent
            text: "chevron_left"
            color: Colors.text
            font.pixelSize: Motion.fontSize.micro
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: slot.moveRequested(-1)
        }
    }

    // Move later badge
    Rectangle {
        visible: slot.editMode && !slot.isLast
        width: 14
        height: 14
        radius: width / 2
        anchors { bottom: parent.bottom; right: parent.right; margins: -2 }
        color: Colors.layer
        border.color: Colors.outline
        border.width: 1

        MaterialIcon {
            anchors.centerIn: parent
            text: "chevron_right"
            color: Colors.text
            font.pixelSize: Motion.fontSize.micro
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: slot.moveRequested(1)
        }
    }
}
