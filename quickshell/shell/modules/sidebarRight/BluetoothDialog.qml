import QtQuick
import QtQuick.Layouts
import "../../services"

// Bluetooth device picker, overlaid on the sidebar's card stack (comparison.md #25)
Rectangle {
    id: root

    radius: 20
    color: Colors.background

    Component.onCompleted: BluetoothStatus.setDiscovering(true)
    Component.onDestruction: BluetoothStatus.setDiscovering(false)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                color: Colors.text
                font.pixelSize: 15
                font.bold: true
            }

            IconAction {
                iconName: "close"
                onTriggered: SidebarDialogState.close()
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: sections.implicitHeight
            clip: true

            ColumnLayout {
                id: sections
                width: parent.width
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: BluetoothStatus.connectedDevices.length > 0

                    Text { text: "Connected"; color: Colors.textMuted; font.pixelSize: 11 }

                    Repeater {
                        model: BluetoothStatus.connectedDevices
                        delegate: BluetoothDeviceItem {
                            required property var modelData
                            Layout.fillWidth: true
                            device: modelData
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: BluetoothStatus.pairedDevices.length > 0

                    Text { text: "Paired"; color: Colors.textMuted; font.pixelSize: 11 }

                    Repeater {
                        model: BluetoothStatus.pairedDevices
                        delegate: BluetoothDeviceItem {
                            required property var modelData
                            Layout.fillWidth: true
                            device: modelData
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: BluetoothStatus.availableDevices.length > 0

                    Text { text: "Available"; color: Colors.textMuted; font.pixelSize: 11 }

                    Repeater {
                        model: BluetoothStatus.availableDevices
                        delegate: BluetoothDeviceItem {
                            required property var modelData
                            Layout.fillWidth: true
                            device: modelData
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    visible: BluetoothStatus.connectedDevices.length === 0 && BluetoothStatus.pairedDevices.length === 0 && BluetoothStatus.availableDevices.length === 0
                    text: BluetoothStatus.discovering ? "Scanning…" : "No devices found"
                    color: Colors.textMuted
                    font.pixelSize: 13
                }
            }
        }
    }
}
