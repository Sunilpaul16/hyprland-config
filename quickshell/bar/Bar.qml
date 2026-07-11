import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// One PanelWindow per monitor (see shell.qml).
//
// Styled after end-4's "hug" bar (Config.qml cornerStyle 0): a flush
// rectangle with square corners; the rounded-transition illusion comes from
// separate Corner shapes below it, not from rounding the bar itself.
PanelWindow {
    id: bar

    readonly property int barContentHeight: 40
    readonly property int cornerSize: 14

    anchors {
        top: true
        left: true
        right: true
    }

    // Includes cornerSize so windows can sit under the transparent decorator
    // strip below — only barContentHeight is reserved as exclusive space.
    implicitHeight: barContentHeight + cornerSize
    exclusiveZone: barContentHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    // Three zones (left/center/right), end-4-style grouped pills — center
    // is anchored to this Rectangle's own horizontal center (not a shared
    // row) so it stays truly centered regardless of side-zone width.
    Rectangle {
        id: content
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: bar.barContentHeight
        color: Colors.background

        // LEFT zone — focused window's icon + title (see ActiveWindow.qml).
        // The SectionPill itself (not just the widget inside) hides when
        // there's nothing to show, so an empty pill never sits here as a
        // stray blob when this monitor doesn't own the focused window.
        SectionPill {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: activeWindow.hasContent

            ActiveWindow {
                id: activeWindow
                screen: bar.screen
            }
        }

        SectionPill {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Workspaces {
                screen: bar.screen
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            RecordingIndicator {
                Layout.alignment: Qt.AlignVCenter
            }

            SectionPill {
                Layout.alignment: Qt.AlignVCenter

                Clock {}
            }
        }
    }

    // Corner decorators: sit directly below content's two bottom corners,
    // same color as the bar, so they read as part of one continuous shape.
    Corner {
        anchors { top: content.bottom; left: parent.left }
        size: bar.cornerSize
        color: Colors.background
        corner: "topLeft"
    }
    Corner {
        anchors { top: content.bottom; right: parent.right }
        size: bar.cornerSize
        color: Colors.background
        corner: "topRight"
    }


}
