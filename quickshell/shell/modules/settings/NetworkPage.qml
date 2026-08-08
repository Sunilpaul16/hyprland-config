import QtQuick
import QtQuick.Layouts
import "../../services"

// Network page
ScrollPage {
    id: root

    title: "Network"

    // Poll while mounted
    Component.onCompleted: {
        NetworkUsage.ref();
        Vpn.ref();
        EthernetStatus.ref();
    }

    Component.onDestruction: {
        NetworkUsage.unref();
        Vpn.unref();
        EthernetStatus.unref();
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
                spacing: Motion.spacing.normal

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
}
