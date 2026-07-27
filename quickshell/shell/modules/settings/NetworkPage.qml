import QtQuick
import QtQuick.Layouts
import "../../services"

// Network page. This machine is wired-only, so Wi-Fi is not modelled here at
// all beyond a row saying so — Wifi.qml still reports hardware presence, and
// the section appears on its own if an adapter ever turns up
ScrollPage {
    id: root

    title: "Network"

    // Throughput and VPN both poll, so only while this page is mounted
    Component.onCompleted: {
        NetworkUsage.ref();
        Vpn.ref();
    }

    Component.onDestruction: {
        NetworkUsage.unref();
        Vpn.unref();
    }

    function speedLabel(bytes: real): string {
        const f = NetworkUsage.formatBytes(bytes);
        return `${f.value.toFixed(f.value < 10 ? 1 : 0)} ${f.unit}`;
    }

    function totalLabel(bytes: real): string {
        const f = NetworkUsage.formatBytesTotal(bytes);
        return `${f.value.toFixed(f.value < 10 ? 1 : 0)} ${f.unit}`;
    }

    SectionLabel {
        text: "Ethernet"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Status"

            ValueLabel {
                text: EthernetStatus.available ? (EthernetStatus.connected ? "Connected" : "Disconnected") : "No adapter"
            }
        }

        SettingRow {
            live: true
            label: "Interface"

            ValueLabel {
                text: EthernetStatus.interfaceName || "—"
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Connection editor"
            subtext: "Opens nm-connection-editor"

            SelectPill {
                value: "Open"
                icon: "open_in_new"
                onClicked: EthernetStatus.openSettings()
            }
        }
    }

    SectionLabel {
        text: "VPN"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "NordVPN"
            subtext: Vpn.available ? "" : "nordvpn CLI not responding"

            RowLayout {
                spacing: 8

                ValueLabel {
                    text: Vpn.statusLabel
                }

                SelectPill {
                    enabled: Vpn.available && !Vpn.busy
                    opacity: enabled ? 1 : 0.5
                    value: Vpn.connected ? "Disconnect" : "Connect"
                    icon: Vpn.connected ? "link_off" : "vpn_key"
                    onClicked: Vpn.toggle()
                }
            }
        }

        SettingRow {
            visible: Vpn.connected
            last: true
            live: true
            label: "Address"

            ValueLabel {
                text: Vpn.ip || "—"
            }
        }

        SettingRow {
            visible: !Vpn.connected
            last: true
            live: true
            label: "Tunnel"

            ValueLabel {
                text: "No active tunnel"
            }
        }
    }

    SectionLabel {
        text: "Throughput"
    }

    SettingGroup {
        SettingRow {
            first: true
            live: true
            label: "Download"

            ValueLabel {
                text: root.speedLabel(NetworkUsage.downloadSpeed)
            }
        }

        SettingRow {
            live: true
            label: "Upload"

            ValueLabel {
                text: root.speedLabel(NetworkUsage.uploadSpeed)
            }
        }

        SettingRow {
            live: true
            label: "Downloaded this session"

            ValueLabel {
                text: root.totalLabel(NetworkUsage.downloadTotal)
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Uploaded this session"

            ValueLabel {
                text: root.totalLabel(NetworkUsage.uploadTotal)
            }
        }
    }

    // Only ever shown if a Wi-Fi adapter appears; this box has none
    SectionLabel {
        visible: Wifi.hardwareAvailable
        text: "Wi-Fi"
    }

    SettingGroup {
        visible: Wifi.hardwareAvailable

        SettingRow {
            first: true
            live: true
            label: "Wi-Fi"

            ToggleSwitch {
                checked: Wifi.enabled
                onToggled: Wifi.toggle()
            }
        }

        SettingRow {
            last: true
            live: true
            label: "Connected network"

            ValueLabel {
                text: Wifi.networkName || "Not connected"
            }
        }
    }
}
