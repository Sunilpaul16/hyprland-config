import QtQuick

// Single session action: normal icon+label, or confirm Yes/Cancel
Item {
    id: root

    required property var action
    property bool confirming: false

    signal activate
    signal confirm
    signal cancel

    readonly property int boxWidth: 120
    readonly property int boxHeight: 110

    implicitWidth: boxWidth
    implicitHeight: boxHeight

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: hoverArea.containsMouse && !root.confirming ? Colors.surface : "transparent"
        border.width: root.confirming ? 1 : 0
        border.color: Colors.error

        Behavior on color { ColorAnimation { duration: 120 } }

        // Normal state: icon + label
        Column {
            anchors.centerIn: parent
            spacing: 8
            opacity: root.confirming ? 0 : 1

            Behavior on opacity { NumberAnimation { duration: 120 } }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.action.icon
                font.pixelSize: 28
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.action.label
                color: Colors.text
                font.pixelSize: 13
            }
        }

        // Confirm state
        Column {
            anchors.centerIn: parent
            spacing: 10
            opacity: root.confirming ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 120 } }

            Text {
                width: root.boxWidth - 16
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Confirm " + root.action.label + "?"
                color: Colors.error
                font.pixelSize: 12
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    width: 44
                    height: 26
                    radius: 8
                    color: yesArea.containsMouse ? Colors.error : Colors.errorContainer

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Yes"
                        color: Colors.textOnErrorContainer
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: yesArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.confirming
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirm()
                    }
                }

                Rectangle {
                    width: 54
                    height: 26
                    radius: 8
                    color: cancelArea.containsMouse ? Colors.outline : Colors.surface

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Colors.text
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.confirming
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancel()
                    }
                }
            }
        }
    }

    // Click to activate (or open confirm)
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.confirming
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }
}
