import "."
import QtQuick
import QtQuick.Layouts
import "../../../services"

// GPU usage ring + temperature (Nvidia only on this box, see Gpu.qml) —
// auto-hides entirely when nvidia-smi isn't available, same pattern as
// BatteryCard's hasBattery gate.
Rectangle {
    id: root

    readonly property bool hasGpu: Gpu.available

    visible: hasGpu
    implicitWidth: hasGpu ? 260 : 0
    implicitHeight: hasGpu ? 140 : 0

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: Gpu.ref()
    Component.onDestruction: Gpu.unref()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14
        visible: root.hasGpu

        UsageRing {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            value: Gpu.percentage
            ringColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round(Gpu.percentage * 100) + "%"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "GPU"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: Math.round(Gpu.temperature) + "°C"
                color: Colors.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
