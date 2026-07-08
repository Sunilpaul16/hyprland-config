import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// One PanelWindow per monitor (see shell.qml). PanelWindow is Quickshell's
// wrapper around the Wayland layer-shell protocol — it's what actually puts
// pixels in a strip Hyprland reserves screen space for, rather than a normal
// application window.
//
// Styled after end-4's "hug" cornerStyle (Config.qml: cornerStyle 0): the
// bar itself is a plain flush rectangle — full width, no margin, no radius,
// no gap from the screen edge — and the illusion of a rounded transition
// into the content area below comes from two small Corner shapes sitting
// right underneath its bottom corners, not from rounding the bar itself.
PanelWindow {
    id: bar

    readonly property int barContentHeight: 40
    readonly property int cornerSize: 14

    anchors {
        top: true
        left: true
        right: true
    }

    // Taller than the bar content alone — the extra `cornerSize` at the
    // bottom is where the Corner decorators live. Only barContentHeight is
    // reserved as exclusive space (below), so windows can sit right under
    // the mostly-transparent decorator strip, same as end-4's hug bar does.
    implicitHeight: barContentHeight + cornerSize
    exclusiveZone: barContentHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    // The bar itself: flush, full-width, square corners. Three zones —
    // left/center/right — styled after end-4's grouped-pill bar layout
    // (ii/modules/ii/bar/BarContent.qml): the center zone is anchored to
    // this Rectangle's own horizontal center, not packed into a shared row
    // with the side zones, so it stays truly centered no matter how wide
    // the left/right content ends up being.
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

        // CENTER zone.
        SectionPill {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Workspaces {
                screen: bar.screen
            }
        }

        // RIGHT zone.
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
