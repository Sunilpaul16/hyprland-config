import QtQuick
import "../../services"
import "../../components"
import "crosshair"

// Overlay canvas
FocusScope {
    id: root

    required property var screen

    Keys.onEscapePressed: OverlayState.open = false

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("#000000", 0.45)
        visible: Config.overlay.darkenScreen && opacity > 0.001
        opacity: OverlayState.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: OverlayState.open = false
        }
    }

    // Widget picker
    Rectangle {
        id: picker
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Motion.spacing.section
        implicitWidth: pickerRow.implicitWidth + Motion.spacing.large
        implicitHeight: pickerRow.implicitHeight + Motion.spacing.normal
        radius: Motion.rounding.drawer
        color: Colors.panel
        opacity: OverlayState.open ? 1 : 0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
        }

        Row {
            id: pickerRow
            anchors.centerIn: parent
            spacing: Motion.spacing.small

            Repeater {
                model: OverlayState.widgets

                Rectangle {
                    id: chip
                    required property var modelData

                    readonly property bool active: OverlayState.entry(chip.modelData.identifier).open ?? false

                    implicitWidth: chipRow.implicitWidth + Motion.spacing.large
                    implicitHeight: chipRow.implicitHeight + Motion.spacing.normal
                    radius: Motion.rounding.normal
                    color: chip.active ? Colors.primary : (chipArea.containsMouse ? Colors.layer : "transparent")

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Motion.spacing.tiny

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.icon
                            color: chip.active ? Colors.textOnPrimary : Colors.text
                            font.pixelSize: Motion.fontSize.subhead
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.label
                            color: chip.active ? Colors.textOnPrimary : Colors.text
                            font.pixelSize: Motion.fontSize.body
                        }
                    }

                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: OverlayState.toggleWidget(chip.modelData.identifier)
                    }
                }
            }
        }
    }

    // Widget canvas
    Item {
        id: widgetCanvas
        anchors.fill: parent

        Repeater {
            model: OverlayState.openIds

            Loader {
                required property string modelData

                active: true
                sourceComponent: modelData === "crosshair" ? crosshairComponent : null
            }
        }
    }

    Component {
        id: crosshairComponent

        Crosshair {
            canvas: widgetCanvas
        }
    }
}
