import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../services"

// Polkit authentication dialog — replaces the system's default (unthemed)
// agent UI for auth prompts. Binds to services/PolkitState.qml's
// PolkitAgent singleton. Same PanelWindow+WlrLayershell overlay idiom as
// Cheatsheet.qml (centered panel, fade+scale, click-outside/absorb,
// Escape-to-cancel).
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: PanelWindow {
                id: root
                screen: panelLoader.modelData

                readonly property bool isOwnerScreen: ScreenOwner.owns(PolkitState, root.screen)
                readonly property bool active: PolkitState.isActive && root.isOwnerScreen
                readonly property var flow: PolkitState.flow

                property real showProgress: active ? 1 : 0

                Behavior on showProgress {
                    NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
                }

                // Positioning
                anchors { top: true; left: true; right: true; bottom: true }

                // Window setup
                color: "transparent"
                exclusiveZone: 0
                visible: showProgress > 0.001

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-polkit"
                WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Grab the password field whenever a fresh flow starts needing one
                onFlowChanged: if (root.flow?.isResponseRequired) passwordInput.forceActiveFocus()
                Connections {
                    target: root.flow
                    function onIsResponseRequiredChanged() {
                        if (root.flow?.isResponseRequired)
                            passwordInput.forceActiveFocus();
                    }
                }

                // Click-through everywhere except the panel itself
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
                        root.flow?.cancelAuthenticationRequest();
                    }
                }

                // Focus scope
                Item {
                    anchors.fill: parent
                    focus: root.active
                    Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                    // Panel
                    Rectangle {
                        id: panel
                        anchors.centerIn: parent
                        width: 380
                        implicitHeight: content.implicitHeight + 48
                        radius: 18
                        color: Colors.background
                        border.width: 1
                        border.color: Colors.outline

                        opacity: root.showProgress
                        scale: 0.96 + 0.04 * root.showProgress
                        transformOrigin: Item.Center

                        ColumnLayout {
                            id: content
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 24
                            spacing: 12

                            // Icon + main message
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                IconImage {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    source: root.flow?.iconName ? Quickshell.iconPath(root.flow.iconName, "dialog-password") : ""
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.flow?.message ?? ""
                                    color: Colors.text
                                    font.pixelSize: 14
                                    wrapMode: Text.WordWrap
                                }
                            }

                            // Error / supplementary message
                            Text {
                                Layout.fillWidth: true
                                visible: (root.flow?.supplementaryMessage ?? "").length > 0
                                text: root.flow?.supplementaryMessage ?? ""
                                color: root.flow?.supplementaryIsError ? Colors.error : Colors.textMuted
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }

                            // Response field — echoMode follows responseVisible (false
                            // for passwords, true for the rare visible-response case)
                            Rectangle {
                                Layout.fillWidth: true
                                visible: root.flow?.isResponseRequired ?? false
                                implicitHeight: 40
                                radius: 8
                                color: Colors.surface
                                border.width: 1
                                border.color: Colors.outline

                                TextInput {
                                    id: passwordInput
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.text
                                    font.pixelSize: 13
                                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                                    clip: true

                                    Keys.onReturnPressed: root.flow?.submit(passwordInput.text)
                                    Keys.onEnterPressed: root.flow?.submit(passwordInput.text)
                                    Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                                    // Clear on every fresh prompt (retry after a failed attempt included)
                                    Connections {
                                        target: root.flow
                                        function onInputPromptChanged() { passwordInput.text = ""; }
                                    }
                                }
                            }

                            // Cancel / Authenticate
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                spacing: 8

                                Item { Layout.fillWidth: true }

                                DialogButton {
                                    text: "Cancel"
                                    onClicked: root.flow?.cancelAuthenticationRequest()
                                }

                                DialogButton {
                                    text: "Authenticate"
                                    primary: true
                                    visible: root.flow?.isResponseRequired ?? false
                                    onClicked: root.flow?.submit(passwordInput.text)
                                }
                            }
                        }
                    }
                }

                component DialogButton: Rectangle {
                    id: btn

                    required property string text
                    property bool primary: false
                    signal clicked()

                    implicitWidth: label.implicitWidth + 24
                    implicitHeight: 32
                    radius: 8
                    color: btn.primary ? Colors.primary : (hoverArea.containsMouse ? Colors.surface : "transparent")
                    border.width: btn.primary ? 0 : 1
                    border.color: Colors.outline

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: btn.text
                        color: btn.primary ? Colors.background : Colors.text
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btn.clicked()
                    }
                }
            }
        }
    }
}
