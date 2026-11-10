import Caelestia.I18n
import qs.modules.nexus.common

RowButton {
    id: root

    required property var network

    icon: "wifi_find"
    text: network.scanning ? Tr.tr("Scanning…") : Tr.tr("Scan for networks")
    disabled: !network.wifiEnabled || network.scanning
    onClicked: root.network.rescanWifi()
}
