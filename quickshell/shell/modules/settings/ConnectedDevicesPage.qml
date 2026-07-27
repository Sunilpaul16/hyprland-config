import QtQuick.Layouts

// Connected devices page. Layout only — the device rows are static stand-ins
// for services/BluetoothStatus.qml's connected/paired/available lists
ScrollPage {
    title: "Connected devices"

    SectionLabel {
        text: "Bluetooth"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Bluetooth"
            subtext: "Turn the adapter on or off"

            ToggleSwitch {
                checked: true
            }
        }

        SettingRow {
            label: "Discoverable"
            subtext: "Let nearby devices find this machine"

            ToggleSwitch {
                checked: false
            }
        }

        SettingRow {
            last: true
            label: "Scan for devices"

            SelectPill {
                value: "Scan"
                icon: "bluetooth_searching"
            }
        }
    }

    SectionLabel {
        text: "Connected"
    }

    SettingGroup {
        SettingRow {
            first: true
            last: true
            label: "WH-1000XM4"
            subtext: "Headphones · battery 80%"

            SelectPill {
                value: "Disconnect"
                icon: "chevron_right"
            }
        }
    }

    SectionLabel {
        text: "Paired"
    }

    SettingGroup {
        SettingRow {
            first: true
            label: "Xbox Wireless Controller"
            subtext: "Gamepad"

            SelectPill {
                value: "Connect"
                icon: "chevron_right"
            }
        }

        SettingRow {
            last: true
            label: "Pixel 8"
            subtext: "Phone"

            SelectPill {
                value: "Connect"
                icon: "chevron_right"
            }
        }
    }
}
