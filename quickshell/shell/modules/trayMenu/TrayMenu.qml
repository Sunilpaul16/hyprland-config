import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

// Tray menu overlay
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: PanelWindow {
                id: root
                screen: panelLoader.modelData

                // Visibility state
                readonly property bool isOwnerScreen: ScreenOwner.owns(TrayMenuState, root.screen)
                readonly property bool active: TrayMenuState.open && TrayMenuState.ready && root.isOwnerScreen

                // Slide-down open
                property real offsetScale: root.active ? 0 : 1
                readonly property int cornerSize: Motion.cornerSize

                Behavior on offsetScale {
                    Anim { type: root.active ? "enter" : "exit" }
                }

                // Positioning
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                // Window setup
                color: "transparent"
                exclusiveZone: 0
                // Mapped while sliding
                visible: offsetScale < 1

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-tray-menu"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Click-through mask
                mask: Region {
                    item: panel
                }

                // Shared focus-grab registration
                onActiveChanged: {
                    if (root.active)
                        GlobalFocusGrab.addDismissable(root);
                    else
                        GlobalFocusGrab.removeDismissable(root);
                }
                Connections {
                    target: GlobalFocusGrab
                    function onDismissed() {
                        TrayMenuState.close();
                    }
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: TrayMenuState.close()

                    // Panel
                    Rectangle {
                        id: panel

                        property real sessionWidth: 0
                        property real settledEntriesHeight: 0

                        // Measure delegates directly
                        readonly property real contentWidth: {
                            let w = searchRow.visible ? 250 : (backRow.visible ? backLabel.implicitWidth + 40 : 0);
                            for (let i = 0; i < entryRepeater.count; i++) {
                                const item = entryRepeater.itemAt(i);
                                if (item)
                                    w = Math.max(w, item.implicitWidth);
                            }
                            return w;
                        }
                        readonly property real maxViewportHeight: Math.min(560, root.height * 0.68)
                        readonly property real headerHeight: (backRow.visible ? backRow.height + Motion.spacing.micro : 0)
                            + (searchRow.visible ? searchRow.height + Motion.spacing.micro : 0)
                        readonly property real naturalWidth: Math.max(160, contentWidth + 12)

                        onContentWidthChanged: {
                            if (TrayMenuState.open && TrayMenuState.menuStack.length === 0)
                                sessionWidth = naturalWidth;
                        }

                        Connections {
                            target: TrayMenuState
                            function onOpenChanged(): void {
                                if (TrayMenuState.open) {
                                    panel.sessionWidth = 0;
                                    panel.settledEntriesHeight = 0;
                                }
                            }
                        }

                        // Anchored to icon
                        x: Math.max(8, Math.min(TrayMenuState.anchorX, root.width - implicitWidth - 8))
                        // Flush below bar
                        anchors.top: parent.top
                        anchors.topMargin: -(panel.height + 5) * root.offsetScale
                        implicitWidth: sessionWidth > 0 ? sessionWidth : naturalWidth
                        implicitHeight: Math.min(settledEntriesHeight, maxViewportHeight)
                            + headerHeight + 12
                        Behavior on implicitHeight {
                            enabled: root.active && root.offsetScale < 0.01
                            NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                        }
                        radius: Motion.rounding.card
                        // Square top corners
                        topLeftRadius: 0
                        topRightRadius: 0
                        color: Colors.panel

                        opacity: 1 - root.offsetScale

                        // Keep navigation visible above long, scrollable menus.
                        Rectangle {
                            id: backRow
                            visible: TrayMenuState.menuStack.length > 0
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: Motion.spacing.small
                            height: visible ? 32 : 0
                            radius: Motion.rounding.tiny
                            color: backArea.containsMouse ? Colors.layer : "transparent"

                            StyledText {
                                id: backLabel
                                anchors.left: parent.left
                                anchors.leftMargin: Motion.spacing.medium
                                anchors.verticalCenter: parent.verticalCenter
                                text: "‹  Back"
                                color: Colors.textMuted
                                font.pixelSize: Motion.fontSize.label
                            }

                            MouseArea {
                                id: backArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TrayMenuState.goBack()
                            }
                        }

                        Rectangle {
                            id: searchRow
                            visible: TrayMenuState.isConnectionsMenu
                            anchors.top: backRow.visible ? backRow.bottom : parent.top
                            anchors.topMargin: backRow.visible ? Motion.spacing.micro : Motion.spacing.small
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Motion.spacing.small
                            anchors.rightMargin: Motion.spacing.small
                            height: visible ? 34 : 0
                            radius: Motion.rounding.tiny
                            color: Colors.layer

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Motion.spacing.medium
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌕"
                                color: Colors.textMuted
                                font.pixelSize: Motion.fontSize.body
                            }

                            StyledText {
                                visible: searchInput.text.length === 0
                                anchors.left: searchInput.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search…"
                                color: Colors.textMuted
                                font.pixelSize: Motion.fontSize.label
                            }

                            TextInput {
                                id: searchInput
                                anchors.left: parent.left
                                anchors.leftMargin: 34
                                anchors.right: parent.right
                                anchors.rightMargin: Motion.spacing.medium
                                anchors.verticalCenter: parent.verticalCenter
                                color: Colors.text
                                selectionColor: Colors.primary
                                selectedTextColor: Colors.background
                                font.pixelSize: Motion.fontSize.label
                                clip: true
                                text: TrayMenuState.searchQuery
                                onTextEdited: TrayMenuState.searchQuery = text
                                Keys.onEscapePressed: event => {
                                    if (text.length > 0) {
                                        TrayMenuState.searchQuery = "";
                                        event.accepted = true;
                                    } else {
                                        TrayMenuState.close();
                                    }
                                }
                            }

                            onVisibleChanged: {
                                if (visible)
                                    Qt.callLater(() => searchInput.forceActiveFocus());
                            }
                        }

                        Flickable {
                            id: menuFlick
                            anchors.top: searchRow.visible ? searchRow.bottom : (backRow.visible ? backRow.bottom : parent.top)
                            anchors.topMargin: (searchRow.visible || backRow.visible) ? Motion.spacing.micro : Motion.spacing.small
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: Motion.spacing.small
                            anchors.rightMargin: Motion.spacing.small
                            anchors.bottomMargin: Motion.spacing.small
                            contentWidth: width
                            contentHeight: entriesColumn.implicitHeight
                            interactive: contentHeight > height
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            Column {
                                id: entriesColumn
                                width: menuFlick.width
                                spacing: Motion.spacing.micro
                                opacity: TrayMenuState.entries.length > 0 ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                                }

                                onImplicitHeightChanged: {
                                    if (TrayMenuState.filteredEntries.length > 0 || TrayMenuState.searchQuery.length > 0)
                                        panel.settledEntriesHeight = implicitHeight;
                                }

                                Repeater {
                                    id: entryRepeater
                                    model: TrayMenuState.filteredEntries

                                    TrayMenuItem {
                                        required property var modelData
                                        entry: modelData
                                        width: entriesColumn.width
                                    }
                                }
                            }

                            onContentHeightChanged: contentY = 0
                        }

                        Rectangle {
                            visible: menuFlick.contentHeight > menuFlick.height
                            z: 2
                            anchors.right: menuFlick.right
                            anchors.rightMargin: 2
                            y: menuFlick.y + (menuFlick.contentY / Math.max(1, menuFlick.contentHeight - menuFlick.height))
                                * (menuFlick.height - height)
                            width: 3
                            height: Math.max(24, menuFlick.height * menuFlick.height / menuFlick.contentHeight)
                            radius: width / 2
                            color: Colors.outline
                            opacity: 0.7
                        }
                    }

                    // Bar fillets
                    Corner {
                        anchors { right: panel.left; top: panel.top }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "topRight"
                        opacity: panel.opacity
                    }

                    Corner {
                        anchors { left: panel.right; top: panel.top }
                        size: root.cornerSize
                        color: Colors.panel
                        corner: "topLeft"
                        opacity: panel.opacity
                    }
                }
            }
        }
    }
}
