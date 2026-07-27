import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../../services"

// Battery ring. PerformanceTab gates this on UPower.displayDevice
// .isLaptopBattery, so nothing here hides itself.
Rectangle {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(device?.state)

    radius: 26
    color: Colors.layer

    implicitWidth: layout.implicitWidth + 44
    implicitHeight: layout.implicitHeight + 32

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Battery"
            color: Colors.text
            font.pixelSize: 15
            font.bold: true
        }

        CircularProgress {
            Layout.alignment: Qt.AlignHCenter

            implicitSize: 96
            startAngle: -225
            sweepAngle: 270
            strokeWidth: 7
            value: root.device?.percentage ?? 0
            fgColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round((root.device?.percentage ?? 0) * 100) + "%"
                color: Colors.primary
                font.pixelSize: 22
                font.bold: true
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.charging ? "Charging" : "On battery"
            color: Colors.textMuted
            font.pixelSize: 12
        }
    }
}
