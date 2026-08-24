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
            extraCondition: BarState.open

            component: PanelWindow {
                id: bar
                screen: panelLoader.modelData

                // Dimensions
                readonly property int barContentHeight: Config.bar.height
                readonly property int cornerSize: Motion.cornerSize
                readonly property int revealHeight: 2

                // Auto-hide state
                readonly property bool autoHide: Config.bar.autoHide.enable
                property bool revealed: false
                readonly property bool slidAway: bar.autoHide && !bar.revealed

                // Absorbs input-region churn
                Timer {
                    id: hideDebounce
                    interval: 250
                    onTriggered: bar.revealed = false
                }

                // Positioning
                anchors {
                    top: true
                    left: true
                    right: true
                }

                // Window setup
                implicitHeight: barContentHeight + cornerSize
                exclusiveZone: bar.autoHide && (!bar.revealed || !Config.bar.autoHide.pushWindows) ? 0 : bar.barContentHeight
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-bar"
                mask: Region {
                    item: barBody
                }

                // Persistent focus grab
                Component.onCompleted: GlobalFocusGrab.addPersistent(bar)
                Component.onDestruction: GlobalFocusGrab.removePersistent(bar)

                // Input region and body
                Item {
                    id: barBody
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: bar.slidAway ? bar.revealHeight : bar.barContentHeight

                    HoverHandler {
                        id: revealHover
                        onHoveredChanged: {
                            if (hovered) {
                                hideDebounce.stop();
                                bar.revealed = true;
                            } else {
                                hideDebounce.restart();
                            }
                        }
                    }

                    // Bar content
                    Rectangle {
                        id: content
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        anchors.topMargin: bar.slidAway ? -bar.barContentHeight : 0
                        height: bar.barContentHeight
                        color: Colors.panel

                        // Slide animation
                        Behavior on anchors.topMargin {
                            Anim { type: "effectsFast" }
                        }
                        // Left-side widgets
                        RowLayout {
                            id: leftRow
                            anchors.left: parent.left
                            anchors.leftMargin: Motion.spacing.wide
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Motion.spacing.normal

                            OsLogo {
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ActiveWindow {
                                id: activeWindow
                                Layout.alignment: Qt.AlignVCenter
                                visible: Config.bar.showWindowTitle && activeWindow.hasContent
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

                            // Dashboard hover zone
                            Item {
                                id: dashboardHoverZone
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 60
                                implicitHeight: bar.barContentHeight

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: dashboardHandleHover.hovered ? 30 : 22
                                    height: 4
                                    radius: height / 2
                                    color: dashboardHandleHover.hovered ? Colors.primary : Colors.textMuted
                                    opacity: dashboardHandleHover.hovered ? 0.9 : 0.45

                                    Behavior on width { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                                    Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                                }

                                HoverHandler {
                                    id: dashboardHandleHover
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

                            // Workspaces pill
                            MouseArea {
                                id: workspaceScrollZone
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: workspacesPill.implicitWidth
                                implicitHeight: workspacesPill.implicitHeight

                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton

                                onWheel: event => {
                                    if (!Config.bar.scroll.workspaces)
                                        return;
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

                        // Scroll hint
                        ScrollHint {
                            visible: Config.bar.scroll.workspaces && Config.bar.scroll.workspacesHint
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

                            Clock {
                                Layout.alignment: Qt.AlignVCenter
                            }

                        }

                        // Volume scroll zone
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
                                if (!Config.bar.scroll.volume)
                                    return;
                                if (event.angleDelta.y < 0)
                                    Audio.decrementVolume();
                                else if (event.angleDelta.y > 0)
                                    Audio.incrementVolume();
                            }

                            ScrollHint {
                                visible: Config.bar.scroll.volume && Config.bar.scroll.volumeHint
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
                        visible: content.anchors.topMargin > -bar.barContentHeight
                        size: bar.cornerSize
                        color: Colors.panel
                        corner: "topLeft"
                    }
                    Corner {
                        id: cornerTR
                        anchors { top: content.bottom; right: parent.right }
                        visible: content.anchors.topMargin > -bar.barContentHeight
                        size: bar.cornerSize
                        color: Colors.panel
                        corner: "topRight"
                    }
                }
            }
        }
    }
}
