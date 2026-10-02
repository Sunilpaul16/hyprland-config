import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"
import "../settings"

Rectangle {
    id: root
    radius: Motion.rounding.large
    color: Colors.layer
    property var selectedNetwork: null

    Component.onCompleted: {
        WifiStatus.ref();
        WifiStatus.pickerOpen = true;
        WifiStatus.scan();
    }
    Component.onDestruction: {
        WifiStatus.pickerOpen = false;
        WifiStatus.unref();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Motion.spacing.xlarge
        spacing: Motion.spacing.large

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: "Wi-Fi"
                font.pixelSize: Motion.fontSize.title
                font.bold: true
            }
            IconAction {
                iconName: "refresh"
                enabled: WifiStatus.enabled && !WifiStatus.scanning && !WifiStatus.busy
                opacity: enabled ? 1 : 0.4
                onTriggered: WifiStatus.scan()
            }
            ToggleSwitch {
                checked: WifiStatus.enabled
                enabled: WifiStatus.available && !WifiStatus.busy
                opacity: enabled ? 1 : 0.4
                onToggled: value => WifiStatus.setEnabled(value)
            }
            IconAction {
                iconName: "close"
                onTriggered: SidebarDialogState.wifiOpen = false
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: WifiStatus.busy ? "Working…" : (WifiStatus.scanning ? "Scanning…" : WifiStatus.statusLabel)
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.label
        }

        StyledText {
            Layout.fillWidth: true
            visible: WifiStatus.error.length > 0
            text: WifiStatus.error
            wrapMode: Text.WordWrap
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.small
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: passwordForm.implicitHeight + 24
            visible: root.selectedNetwork !== null && WifiStatus.enabled
            color: Colors.layer
            radius: Motion.rounding.normal

            ColumnLayout {
                id: passwordForm
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: Motion.spacing.normal
                StyledText {
                    Layout.fillWidth: true
                    text: root.selectedNetwork ? root.selectedNetwork.ssid : ""
                    elide: Text.ElideRight
                    font.pixelSize: Motion.fontSize.label
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: Motion.rounding.small
                    color: Colors.panel
                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Colors.text
                        font.pixelSize: Motion.fontSize.label
                        echoMode: TextInput.Password
                        selectByMouse: true
                        clip: true
                        enabled: !WifiStatus.busy
                        onAccepted: connectButton.clicked()
                    }
                    StyledText {
                        anchors.fill: password
                        visible: password.text.length === 0
                        text: "Password (leave blank for saved networks)"
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.small
                        elide: Text.ElideRight
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    SelectPill {
                        id: connectButton
                        value: "Connect"
                        icon: "wifi"
                        enabled: !WifiStatus.busy
                        onClicked: {
                            if (!root.selectedNetwork || WifiStatus.busy) return;
                            WifiStatus.connectNetwork(root.selectedNetwork, password.text);
                            password.text = "";
                            root.selectedNetwork = null;
                        }
                    }
                    IconAction {
                        iconName: "close"
                        onTriggered: { root.selectedNetwork = null; password.text = ""; }
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: networksColumn.implicitHeight
            clip: true
            ColumnLayout {
                id: networksColumn
                width: parent.width
                spacing: Motion.spacing.large

                Repeater {
                    model: WifiStatus.enabled ? WifiStatus.networks : []
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Motion.spacing.medium
                        MaterialIcon {
                            text: modelData.active ? "wifi" : (modelData.signal >= 65 ? "network_wifi" : "network_wifi_2_bar")
                            color: modelData.active ? Colors.primary : Colors.textMuted
                            font.pixelSize: Motion.fontSize.header
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                font.pixelSize: Motion.fontSize.label
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: `${modelData.active ? "Connected · " : ""}${modelData.signal}% · ${modelData.security && modelData.security !== "--" ? modelData.security : "Open"}`
                                color: Colors.textMuted
                                font.pixelSize: Motion.fontSize.small
                                elide: Text.ElideRight
                            }
                        }
                        IconAction {
                            iconName: modelData.active ? "link_off" : "add_link"
                            enabled: !WifiStatus.busy
                            opacity: enabled ? 1 : 0.4
                            onTriggered: {
                                if (modelData.active) WifiStatus.disconnect();
                                else if (modelData.security.includes("802.1X")) WifiStatus.openSettings();
                                else if (!modelData.security || modelData.security === "--") WifiStatus.connectNetwork(modelData, "");
                                else {
                                    root.selectedNetwork = modelData;
                                    password.text = "";
                                    password.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: !WifiStatus.available || !WifiStatus.enabled || (!WifiStatus.scanning && WifiStatus.networks.length === 0)
                    text: !WifiStatus.available ? "No Wi-Fi adapter" : (!WifiStatus.enabled ? "Turn on Wi-Fi to find networks" : "No networks found. Try refreshing.")
                    color: Colors.textMuted
                    wrapMode: Text.WordWrap
                    font.pixelSize: Motion.fontSize.label
                }
            }
        }
        SelectPill {
            value: "Connection editor"
            icon: "open_in_new"
            onClicked: WifiStatus.openSettings()
        }
    }
}
