import QtQuick
import Quickshell
import "../../services"

// Small dropdown for picking the recording mode, anchored to the SplitButton's chevron (comparison.md #49)
Loader {
    id: root

    required property Item anchorItem
    property bool shown: false

    signal itemSelected(string value)

    active: root.shown

    sourceComponent: PopupWindow {
        visible: true
        anchor {
            window: root.anchorItem.QsWindow.window
            item: root.anchorItem
            edges: Edges.Bottom
            gravity: Edges.Bottom
            margins.top: 6
        }

        color: "transparent"
        implicitWidth: 110
        implicitHeight: column.implicitHeight + 8

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.layer
            border.width: 1
            border.color: Colors.outline

            Column {
                id: column
                anchors { fill: parent; margins: 4 }
                spacing: 2

                Repeater {
                    model: [{ value: "full", label: "Full" }, { value: "region", label: "Region" }]

                    Rectangle {
                        id: entry
                        required property var modelData

                        width: column.width
                        implicitHeight: 30
                        radius: Motion.rounding.small
                        color: Recorder.mode === entry.modelData.value ? Colors.primary : (hoverArea.containsMouse ? Colors.panel : "transparent")

                        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                        Text {
                            anchors.centerIn: parent
                            text: entry.modelData.label
                            color: Recorder.mode === entry.modelData.value ? Colors.background : Colors.text
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.itemSelected(entry.modelData.value)
                        }
                    }
                }
            }
        }
    }
}
