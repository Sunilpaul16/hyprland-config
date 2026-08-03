import QtQuick
import "../../services"

// Connected devices page
ScrollPage {
    id: root

    title: "Connected devices"

    SectionLabel {
        text: "Bluetooth"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Bluetooth"
            subtext: BluetoothStatus.available ? (BluetoothStatus.adapterName || "Adapter ready") : "No adapter found"

            ToggleSwitch {
                checked: BluetoothStatus.enabled
                onToggled: BluetoothStatus.toggle()
            }
        }

        SettingRow {
            live: true
            label: "Discoverable"
            subtext: "Let nearby devices find this machine"

            ToggleSwitch {
                checked: BluetoothStatus.discoverable
                onToggled: v => BluetoothStatus.setDiscoverable(v)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Scan for devices"
            subtext: BluetoothStatus.discovering ? "Scanning…" : "Look for nearby devices to pair"

            SelectPill {
                value: BluetoothStatus.discovering ? "Stop" : "Scan"
                icon: BluetoothStatus.discovering ? "stop_circle" : "bluetooth_searching"
                onClicked: BluetoothStatus.setDiscovering(!BluetoothStatus.discovering)
            }
        }
    }

    SectionLabel {
        text: "Connected"
    }

    SettingGroup {
        Repeater {
            model: BluetoothStatus.connectedDevices

            BluetoothDeviceRow {
                required property int index
                required property var modelData

                device: modelData
                first: index === 0
                last: index === BluetoothStatus.connectedDevices.length - 1
            }
        }

        SettingRow {
            visible: BluetoothStatus.connectedDevices.length === 0
            first: true
            last: true
            live: true
            label: "Nothing connected"
        }
    }

    SectionLabel {
        text: "Paired"
    }

    SettingGroup {
        Repeater {
            model: BluetoothStatus.pairedDevices

            BluetoothDeviceRow {
                required property int index
                required property var modelData

                device: modelData
                first: index === 0
                last: index === BluetoothStatus.pairedDevices.length - 1
            }
        }

        SettingRow {
            visible: BluetoothStatus.pairedDevices.length === 0
            first: true
            last: true
            live: true
            label: "No paired devices"
        }
    }

    SectionLabel {
        text: "Available"
    }

    // Discovered only
    SettingGroup {
        Repeater {
            model: BluetoothStatus.availableDevices

            BluetoothDeviceRow {
                required property int index
                required property var modelData

                device: modelData
                first: index === 0
                last: index === BluetoothStatus.availableDevices.length - 1
            }
        }

        SettingRow {
            visible: BluetoothStatus.availableDevices.length === 0
            first: true
            last: true
            live: true
            label: BluetoothStatus.discovering ? "Searching…" : "Start a scan to find devices"
        }
    }
}
