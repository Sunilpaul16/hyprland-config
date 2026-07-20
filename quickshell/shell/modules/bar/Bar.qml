import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"

// Bar window
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: PanelWindow {
                id: bar
                screen: panelLoader.modelData

                // Dimensions
                readonly property int barContentHeight: Config.barHeight
                readonly property int cornerSize: 14
                // Extra window height below the corners so tray tooltips have room to
                // draw without being clipped by the surface bounds
                readonly property int tooltipReserve: 24

                // Positioning
                anchors {
                    top: true
                    left: true
                    right: true
                }

                // Window setup
                implicitHeight: barContentHeight + cornerSize + tooltipReserve
                exclusiveZone: barContentHeight
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-bar"

                // Restrict input to the visible bar chrome so the extra tooltip
                // clearance below the corners stays click-through
                mask: Region {
                    Region { item: content }
                    Region { item: cornerTL }
                    Region { item: cornerTR }
                }
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

                    // Center widgets
                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Media button
                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter
                            visible: Media.hasPlayer

                            MediaButton {}
                        }

                        // Workspaces pill
                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter

                            Workspaces {
                                screen: bar.screen
                            }
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
                    id: cornerTL
                    anchors { top: content.bottom; left: parent.left }
                    size: bar.cornerSize
                    color: Colors.background
                    corner: "topLeft"
                }
                Corner {
                    id: cornerTR
                    anchors { top: content.bottom; right: parent.right }
                    size: bar.cornerSize
                    color: Colors.background
                    corner: "topRight"
                }
            }
        }
    }
}
