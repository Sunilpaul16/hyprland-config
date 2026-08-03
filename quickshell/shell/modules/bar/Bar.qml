import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../../components"

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
                readonly property int barContentHeight: Config.bar.height
                readonly property int cornerSize: 14

                // Positioning
                anchors {
                    top: true
                    left: true
                    right: true
                }

                // Window setup — no reserved height needed, tray tooltips are their own PopupWindow now
                implicitHeight: barContentHeight + cornerSize
                exclusiveZone: barContentHeight
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-bar"

                // Stay inside any active focus grab, or the compositor cuts pointer input to the bar while an overlay is open
                Component.onCompleted: GlobalFocusGrab.addPersistent(bar)
                Component.onDestruction: GlobalFocusGrab.removePersistent(bar)

                // Bar content
                Rectangle {
                    id: content
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: bar.barContentHeight
                    color: Colors.panel
                    // Active window pill
                    SectionPill {
                        anchors.left: parent.left
                        anchors.leftMargin: Motion.spacing.wide
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Config.bar.showWindowTitle && activeWindow.hasContent

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
                        spacing: Motion.spacing.normal

                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter
                            visible: Media.hasPlayer

                            MediaButton {}
                        }

                        // Hover-to-open dashboard trigger — invisible zone,
                        // spans the bar's full content height (40h)
                        Item {
                            id: dashboardHoverZone
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 60 // TEMP: debug sizing
                            implicitHeight: bar.barContentHeight

                            HoverHandler {
                                target: dashboardHoverZone
                                onHoveredChanged: {
                                    if (hovered) {
                                        DashboardState.cancelHoverClose();
                                        DashboardState.show();
                                    } else {
                                        DashboardState.scheduleHoverClose();
                                    }
                                }
                            }
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
                        anchors.leftMargin: Motion.spacing.small
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Right-side widgets
                    RowLayout {
                        id: rightRow
                        anchors.right: parent.right
                        anchors.rightMargin: Motion.spacing.wide
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Motion.spacing.normal

                        // Recording indicator
                        RecordingIndicator {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        PrivacyIndicator {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter
                            horizontalPadding: 8
                            visible: notifIndicator.active

                            NotifIndicator {
                                id: notifIndicator
                            }
                        }

                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter
                            horizontalPadding: 8
                            visible: updatesIndicator.active

                            UpdatesIndicator {
                                id: updatesIndicator
                            }
                        }

                        // Tray
                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter
                            visible: Config.bar.showTray && tray.hasItems

                            Tray {
                                id: tray
                            }
                        }

                        // Clock
                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter

                            Clock {}
                        }

                    }

                    // Volume scroll zone — the open gap left of the tray/clock cluster
                    MouseArea {
                        id: volumeScrollZone
                        anchors {
                            left: centerRow.right
                            leftMargin: Motion.spacing.large
                            right: rightRow.left
                            rightMargin: Motion.spacing.normal
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
                    color: Colors.panel
                    corner: "topLeft"
                }
                Corner {
                    id: cornerTR
                    anchors { top: content.bottom; right: parent.right }
                    size: bar.cornerSize
                    color: Colors.panel
                    corner: "topRight"
                }
            }
        }
    }
}
