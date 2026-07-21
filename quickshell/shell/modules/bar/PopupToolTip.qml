import QtQuick
import Quickshell
import "../../services"

// Hover tooltip rendered as its own PopupWindow, anchored to `hoverTarget` —
// escapes the enclosing bar PanelWindow's clip bounds entirely instead of
// needing a reserved-height + mask workaround (comparison.md #22)
Loader {
    id: root

    required property Item hoverTarget
    property string text: ""
    property bool shown: false

    active: root.shown && root.text.length > 0

    sourceComponent: PopupWindow {
        visible: true
        anchor {
            window: root.hoverTarget.QsWindow.window
            item: root.hoverTarget
            edges: Edges.Bottom
            gravity: Edges.Bottom
            margins.top: 8
        }
        // Non-interactive — clicks/hover pass straight through to whatever's beneath
        mask: Region {
            item: null
        }

        color: "transparent"
        implicitWidth: label.implicitWidth + 20
        implicitHeight: label.implicitHeight + 14

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Colors.surface
            border.width: 1
            border.color: Colors.outline

            Text {
                id: label
                anchors.centerIn: parent
                text: root.text
                color: Colors.text
                font.pixelSize: 12
            }
        }
    }
}
