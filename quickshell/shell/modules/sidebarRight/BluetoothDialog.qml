import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Bluetooth device picker, overlaid on the sidebar's card stack (comparison.md #25)
Rectangle {
    id: root

    radius: Motion.rounding.drawer
    color: Colors.panel

    Component.onCompleted: BluetoothStatus.setDiscovering(true)
    Component.onDestruction: BluetoothStatus.setDiscovering(false)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: "Bluetooth"
                font.pixelSize: Motion.fontSize.title
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

                    StyledText { text: "Connected"; color: Colors.textMuted; font.pixelSize: Motion.fontSize.small }

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

                    StyledText { text: "Paired"; color: Colors.textMuted; font.pixelSize: Motion.fontSize.small }

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

                    StyledText { text: "Available"; color: Colors.textMuted; font.pixelSize: Motion.fontSize.small }

                    Repeater {
                        model: BluetoothStatus.availableDevices
                        delegate: BluetoothDeviceItem {
                            required property var modelData
                            Layout.fillWidth: true
                            device: modelData
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    visible: BluetoothStatus.connectedDevices.length === 0 && BluetoothStatus.pairedDevices.length === 0 && BluetoothStatus.availableDevices.length === 0
                    text: BluetoothStatus.discovering ? "Scanning…" : "No devices found"
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.label
                }
            }
        }
    }
}
