import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Multi-player selector — only shown with >1 active MPRIS player.
// Owns its own dropdown state; the tab supplies the click-outside catcher,
// which has to cover the whole tab rather than just this corner
Item {
    id: root

    property bool menuOpen: false

    function closeMenu(): void {
        root.menuOpen = false;
    }

    visible: Media.hasMultiplePlayers
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Rectangle {
        id: pill

        implicitWidth: pillRow.implicitWidth + 20
        implicitHeight: pillRow.implicitHeight + 12
        radius: implicitHeight / 2
        color: root.menuOpen ? Colors.layer : (pillHover.containsMouse ? Colors.layer : "transparent")
        border.width: 1
        border.color: Colors.outline

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            StyledText {
                text: Media.hasManualPlayer ? (Media.activePlayer?.identity || Media.activePlayer?.dbusName || "Unknown") : "Auto"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: root.menuOpen ? "expand_less" : "expand_more"
                font.pixelSize: 16
                color: Colors.textMuted
            }
        }

        MouseArea {
            id: pillHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    // Dropdown list
    Rectangle {
        id: dropdown

        visible: root.menuOpen
        anchors.top: pill.bottom
        anchors.right: parent.right
        anchors.topMargin: 6
        implicitWidth: Math.max(pill.implicitWidth, list.implicitWidth + 12)
        implicitHeight: list.implicitHeight + 12
        radius: Motion.rounding.normal
        // Surface, not background — this sits on top of the dashboard
        // panel's own Colors.background, so it needs contrast against it
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline

        Column {
            id: list
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6
            spacing: 2

            PlayerMenuEntry {
                label: "Auto"
                selected: !Media.hasManualPlayer
                onClicked: {
                    Media.clearPlayerOverride();
                    root.menuOpen = false;
                }
            }

            Repeater {
                model: Media.players

                PlayerMenuEntry {
                    required property var modelData

                    label: modelData.identity || modelData.dbusName || "Unknown"
                    selected: Media.hasManualPlayer && Media.activePlayer === modelData
                    onClicked: {
                        Media.selectPlayer(modelData);
                        root.menuOpen = false;
                    }
                }
            }
        }
    }

    component PlayerMenuEntry: Rectangle {
        id: entry

        required property string label
        property bool selected: false
        signal clicked()

        implicitWidth: entryRow.implicitWidth + 20
        implicitHeight: entryRow.implicitHeight + 10
        radius: 6
        color: entryHover.containsMouse ? Colors.layer : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        RowLayout {
            id: entryRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 8

            StyledText {
                text: entry.selected ? "\u{25CF}" : ""
                color: Colors.primary
                font.pixelSize: 9
                Layout.preferredWidth: 9
            }

            StyledText {
                Layout.fillWidth: true
                text: entry.label
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: entryHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: entry.clicked()
        }
    }
}
