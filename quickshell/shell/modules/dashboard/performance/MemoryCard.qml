import "."
import QtQuick
import QtQuick.Layouts
import "../../../services"

// Memory usage ring + used/total
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: SystemUsage.ref()
    Component.onDestruction: SystemUsage.unref()

    // Plain KiB -> MiB/GiB scaling helper (not a service — memory-card-local formatting only)
    function formatKib(kib: real): string {
        if (!isFinite(kib) || kib < 0)
            return "0 KiB";
        if (kib >= 1024 * 1024)
            return (kib / (1024 * 1024)).toFixed(1) + " GiB";
        if (kib >= 1024)
            return (kib / 1024).toFixed(1) + " MiB";
        return Math.round(kib) + " KiB";
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        UsageRing {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            value: SystemUsage.memoryPercentage
            ringColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round(SystemUsage.memoryPercentage * 100) + "%"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Memory"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.formatKib(SystemUsage.memoryUsedKib) + " / " + root.formatKib(SystemUsage.memoryTotalKib)
                color: Colors.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
