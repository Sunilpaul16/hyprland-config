import "."
import QtQuick
import QtQuick.Layouts
import "../../../services"

// CPU usage ring + model name
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: SystemUsage.ref()
    Component.onDestruction: SystemUsage.unref()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        UsageRing {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            value: SystemUsage.cpuPercentage
            ringColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round(SystemUsage.cpuPercentage * 100) + "%"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "CPU"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: SystemUsage.cpuName.length > 0 ? SystemUsage.cpuName : "Unknown CPU"
                color: Colors.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
