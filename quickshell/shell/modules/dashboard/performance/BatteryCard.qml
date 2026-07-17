import "."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../../services"

// Battery ring — auto-hides entirely on hardware with no laptop battery
// (UPower.displayDevice.isLaptopBattery gates both visibility and layout
// size, so PerformanceTab's grid cleanly reflows around it).
Rectangle {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device?.isLaptopBattery ?? false
    readonly property bool charging: hasBattery && [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(device.state)

    visible: hasBattery
    implicitWidth: hasBattery ? 260 : 0
    implicitHeight: hasBattery ? 140 : 0

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14
        visible: root.hasBattery

        UsageRing {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            value: root.device?.percentage ?? 0
            ringColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round((root.device?.percentage ?? 0) * 100) + "%"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Battery"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.charging ? "Charging" : "On battery"
                color: Colors.textMuted
                font.pixelSize: 11
            }
        }
    }
}
