import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"


// Bar window
PanelWindow {
    id: bar

    // Dimensions
    readonly property int barContentHeight: Config.barHeight
    readonly property int cornerSize: 14

    // Positioning
    anchors {
        top: true
        left: true
        right: true
    }

    // Window setup
    implicitHeight: barContentHeight + cornerSize
    exclusiveZone: barContentHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    // Bar content
    Rectangle {
        id: content
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: bar.barContentHeight
        color: Colors.background
        // Active window pill
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

        // Workspaces pill
        SectionPill {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Workspaces {
                screen: bar.screen
            }
        }

        // Right-side widgets
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Recording indicator
            RecordingIndicator {
                Layout.alignment: Qt.AlignVCenter
            }

            // Media button
            SectionPill {
                Layout.alignment: Qt.AlignVCenter
                visible: Media.hasPlayer

                MediaButton {}
            }

            // Tray
            SectionPill {
                Layout.alignment: Qt.AlignVCenter
                visible: tray.hasItems

                Tray {
                    id: tray
                }
            }

            // Clock
            SectionPill {
                Layout.alignment: Qt.AlignVCenter

                Clock {}
            }

            // Notification button
            SectionPill {
                Layout.alignment: Qt.AlignVCenter
                horizontalPadding: 8

                NotifButton {}
            }

            // Sidebar toggle button
            SectionPill {
                Layout.alignment: Qt.AlignVCenter
                horizontalPadding: 8

                SidebarRightButton {}
            }

            // Session/power button
            SectionPill {
                Layout.alignment: Qt.AlignVCenter
                horizontalPadding: 8

                SessionButton {}
            }
        }
    }
    // Round decorators
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
