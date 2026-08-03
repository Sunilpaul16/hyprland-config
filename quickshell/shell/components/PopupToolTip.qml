import QtQuick
import Quickshell
import "../services"

// Tooltip popup
Loader {
    id: root

    required property Item hoverTarget
    property string text: ""
    property bool shown: false

    active: root.shown && root.text.length > 0

    sourceComponent: PopupWindow {
        visible: true
        anchor {
            item: root.hoverTarget
            edges: Edges.Bottom
            gravity: Edges.Bottom
            margins.top: 8
        }
        // Click-through
        mask: Region {
            item: null
        }

        color: "transparent"
        implicitWidth: label.implicitWidth + 20
        implicitHeight: label.implicitHeight + 14

        Rectangle {
            anchors.fill: parent
            radius: Motion.rounding.small
            color: Colors.surface
            border.width: 1
            border.color: Colors.outline

            StyledText {
                id: label
                anchors.centerIn: parent
                text: root.text
                font.pixelSize: Motion.fontSize.body
            }
        }
    }
}
