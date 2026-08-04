import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../services"
import "../../components"

// Polkit dialog
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: OverlayWindow {
                id: root
                screen: panelLoader.modelData
                state: PolkitState
                namespace: "quickshell-polkit"
                maskItem: panel

                onDismissed: root.flow?.cancelAuthenticationRequest()
                onEscapePressed: root.flow?.cancelAuthenticationRequest()

                readonly property var flow: PolkitState.flow

                // Focus password field
                onFlowChanged: if (root.flow?.isResponseRequired) passwordInput.forceActiveFocus()
                Connections {
                    target: root.flow
                    function onIsResponseRequiredChanged() {
                        if (root.flow?.isResponseRequired)
                            passwordInput.forceActiveFocus();
                    }
                }

                // Panel
                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: 380
                    implicitHeight: content.implicitHeight + 48
                    radius: Motion.rounding.large
                    color: Colors.panel
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
                        anchors.margins: Motion.spacing.section
                        spacing: Motion.spacing.large

                        // Icon and message
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Motion.spacing.large

                            IconImage {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                source: root.flow?.iconName ? Quickshell.iconPath(root.flow.iconName, "dialog-password") : ""
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.flow?.message ?? ""
                                font.pixelSize: Motion.fontSize.subhead
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Error message
                        StyledText {
                            Layout.fillWidth: true
                            visible: (root.flow?.supplementaryMessage ?? "").length > 0
                            text: root.flow?.supplementaryMessage ?? ""
                            color: root.flow?.supplementaryIsError ? Colors.error : Colors.textMuted
                            font.pixelSize: Motion.fontSize.body
                            wrapMode: Text.WordWrap
                        }

                        // Response field
                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.flow?.isResponseRequired ?? false
                            implicitHeight: 40
                            radius: Motion.rounding.small
                            color: Colors.layer
                            border.width: 1
                            border.color: Colors.outline

                            TextInput {
                                id: passwordInput
                                anchors.fill: parent
                                anchors.margins: Motion.spacing.medium
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.text
                                font.pixelSize: Motion.fontSize.label
                                echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                                clip: true

                                Keys.onReturnPressed: root.flow?.submit(passwordInput.text)
                                Keys.onEnterPressed: root.flow?.submit(passwordInput.text)
                                Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                                // Clear on prompt
                                Connections {
                                    target: root.flow
                                    function onInputPromptChanged() { passwordInput.text = ""; }
                                }
                            }
                        }

                        // Cancel / Authenticate
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Motion.spacing.tiny
                            spacing: Motion.spacing.normal

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

                component DialogButton: Rectangle {
                    id: btn

                    required property string text
                    property bool primary: false
                    signal clicked()

                    implicitWidth: label.implicitWidth + 24
                    implicitHeight: 32
                    radius: Motion.rounding.small
                    color: btn.primary ? Colors.primary : (hoverArea.containsMouse ? Colors.layer : "transparent")
                    border.width: btn.primary ? 0 : 1
                    border.color: Colors.outline

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    StyledText {
                        id: label
                        anchors.centerIn: parent
                        text: btn.text
                        color: btn.primary ? Colors.textOnPrimary : Colors.text
                        font.pixelSize: Motion.fontSize.body
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
