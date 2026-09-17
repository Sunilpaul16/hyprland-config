import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// A grouped settings destination that opens real settings immediately.
PageBase {
    id: root

    required property var sections
    property int currentSection: 0

    signal sectionSelected(int index)

    readonly property var currentEntry: root.sections[Math.max(0, Math.min(root.currentSection, root.sections.length - 1))]

    content: Item {
        anchors.fill: parent

        Flickable {
            id: sectionNav

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 40
            contentWidth: sectionRow.implicitWidth
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            RowLayout {
                id: sectionRow

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Motion.spacing.small

                Repeater {
                    model: root.sections

                    delegate: Rectangle {
                        id: sectionButton

                        required property var modelData
                        required property int index

                        implicitWidth: buttonLayout.implicitWidth + 32
                        implicitHeight: 36
                        radius: height / 2
                        color: index === root.currentSection || buttonMouse.containsMouse
                            ? Colors.secondaryContainer : Colors.layer

                        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                        RowLayout {
                            id: buttonLayout

                            anchors.centerIn: parent
                            spacing: Motion.spacing.small

                            MaterialIcon {
                                text: sectionButton.modelData.icon ?? ""
                                color: sectionButton.index === root.currentSection ? Colors.primary : Colors.textMuted
                                font.pixelSize: 17
                                fill: sectionButton.index === root.currentSection ? 1 : 0
                            }

                            StyledText {
                                text: sectionButton.modelData.label
                                font.pixelSize: Motion.fontSize.subhead
                            }
                        }

                        MouseArea {
                            id: buttonMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SettingsState.closeSubPage();
                                root.sectionSelected(sectionButton.index);
                            }
                        }
                    }
                }
            }
        }

        Loader {
            id: sectionLoader

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: sectionNav.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: Motion.spacing.large
            sourceComponent: root.currentEntry?.component ?? null

            onLoaded: {
                if (item)
                    item.showHeader = false;
            }
        }
    }
}
