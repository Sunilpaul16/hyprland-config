import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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

                // Positioning
                anchors {
                    top: true
                    left: true
                    right: true
                }

                // Window setup — no extra reserved height needed: tray tooltips are
                // their own PopupWindow (PopupToolTip.qml), not clipped by this
                // window's bounds, so it can be sized exactly to its visible chrome
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

                    // Center widgets
                    RowLayout {
                        id: centerRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Media button
                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter
                            visible: Media.hasPlayer

                            MediaButton {}
                        }

                        // Workspaces pill — scroll to switch workspace
                        MouseArea {
                            id: workspaceScrollZone
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: workspacesPill.implicitWidth
                            implicitHeight: workspacesPill.implicitHeight

                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton

                            onWheel: event => {
                                if (event.angleDelta.y < 0)
                                    Hyprland.dispatch(`hl.dsp.focus({ workspace = "e+1" })`);
                                else if (event.angleDelta.y > 0)
                                    Hyprland.dispatch(`hl.dsp.focus({ workspace = "e-1" })`);
                            }

                            SectionPill {
                                id: workspacesPill
                                anchors.fill: parent

                                Workspaces {
                                    screen: bar.screen
                                }
                            }
                        }
                    }

                    // Workspace scroll hint — fades in over the gap to the right of centerRow
                    ScrollHint {
                        reveal: workspaceScrollZone.containsMouse
                        icon: "swap_horiz"
                        anchors.left: centerRow.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Right-side widgets
                    RowLayout {
                        id: rightRow
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

                    // Volume scroll zone — the open gap between center content and
                    // the tray/clock cluster, left of the tray so it doesn't compete
                    // with tray icon hover/click targets
                    MouseArea {
                        id: volumeScrollZone
                        anchors {
                            left: centerRow.right
                            leftMargin: 12
                            right: rightRow.left
                            rightMargin: 8
                            top: parent.top
                            bottom: parent.bottom
                        }

                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton

                        onWheel: event => {
                            if (event.angleDelta.y < 0)
                                Audio.decrementVolume();
                            else if (event.angleDelta.y > 0)
                                Audio.incrementVolume();
                        }

                        ScrollHint {
                            reveal: volumeScrollZone.containsMouse
                            icon: "volume_up"
                            anchors.centerIn: parent
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
