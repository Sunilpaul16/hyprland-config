pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

// Notification popup window
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
                // Hyprland may recreate its monitor wrapper objects on reload;
                // compare their stable names rather than object identity.
                readonly property bool isFocusedScreen: root.screen.name === ScreenOwner.focusedName
                property int activeRemovals: 0

                // Layout constants
                readonly property int cardWidth: 340
                readonly property int topGap: 10
                readonly property int sideGap: 10
                readonly property int cardSpacing: 8

                // Popup corner
                readonly property bool atTop: Config.notifications.popupPosition.startsWith("top")
                readonly property bool atRight: Config.notifications.popupPosition.endsWith("right")

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

                visible: list.count > 0 || root.activeRemovals > 0

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-notifications"

                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                // Click-through mask
                mask: Region {
                    item: stack
                }

                // Popup stack container
                Item {
                    id: stack

                    anchors.top: root.atTop ? parent.top : undefined
                    anchors.bottom: root.atTop ? undefined : parent.bottom
                    anchors.right: root.atRight ? parent.right : undefined
                    anchors.left: root.atRight ? undefined : parent.left
                    anchors.topMargin: root.atTop ? root.topGap : 0
                    anchors.bottomMargin: root.atTop ? 0 : root.topGap
                    anchors.rightMargin: root.atRight ? root.sideGap : 0
                    anchors.leftMargin: root.atRight ? 0 : root.sideGap

                    width: root.cardWidth
                    height: Math.min(list.contentHeight, root.height - root.topGap - root.sideGap)
                    clip: true

                    // Popup list
                    ListView {
                        id: list

                        anchors.fill: parent
                        interactive: contentHeight > height
                        spacing: 0
                        cacheBuffer: root.height
                        // Newest nearest edge
                        verticalLayoutDirection: root.atTop ? ListView.TopToBottom : ListView.BottomToTop

                        model: root.isFocusedScreen ? Notifs.popups : []

                        delegate: Wrapper {}

                        move: Transition {
                            NumberAnimation { property: "y"; duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                        }
                        displaced: Transition {
                            NumberAnimation { property: "y"; duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                        }
                    }
                }

                // Per-notification wrapper
                component Wrapper: Item {
                    id: wrapper

                    required property Notif modelData
                    required property int index

                    property Notif notif
                    onModelDataChanged: if (modelData) notif = modelData
                    Component.onCompleted: if (modelData) notif = modelData

                    property int idx
                    onIndexChanged: if (index !== -1) idx = index

                    implicitWidth: stack.width
                    implicitHeight: card.implicitHeight + (idx === 0 ? 0 : root.cardSpacing)

                    ListView.onRemove: {
                        root.activeRemovals++;
                        removeAnim.start();
                    }

                    // Remove animation
                    SequentialAnimation {
                        id: removeAnim

                        PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: true }
                        PropertyAction { target: wrapper; property: "enabled"; value: false }
                        NumberAnimation {
                            target: card
                            property: "x"
                            // Slide out
                            to: root.atRight ? stack.width : -stack.width
                            duration: Motion.deliberateDuration
                            easing.type: Motion.deliberateEasing
                        }
                        NumberAnimation {
                            target: wrapper
                            property: "implicitHeight"
                            to: 0
                            duration: Motion.deliberateDuration
                            easing.type: Motion.deliberateEasing
                        }
                        ScriptAction { script: root.activeRemovals = Math.max(0, root.activeRemovals - 1) }
                        PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: false }
                    }

                    ToastCard {
                        id: card

                        modelData: wrapper.notif ?? wrapper.modelData
                        enterFromRight: root.atRight
                        width: stack.width
                        anchors.top: parent.top
                        anchors.topMargin: wrapper.idx === 0 ? 0 : root.cardSpacing
                    }
                }
            }
        }
    }
}
