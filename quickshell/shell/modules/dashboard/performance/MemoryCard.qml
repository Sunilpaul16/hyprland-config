import QtQuick
import QtQuick.Layouts
import "../../sidebarRight"
import "../../../services"

// Memory: 270° usage arc with percentage inside, used/total underneath.
// Ported from caelestia's performance/MemoryCard.qml.
Rectangle {
    id: root

    readonly property color accent: Colors.tertiary

    radius: 26
    color: Colors.surface

    implicitWidth: layout.implicitWidth + 44
    implicitHeight: layout.implicitHeight + 32

    Component.onCompleted: SystemUsage.ref()
    Component.onDestruction: SystemUsage.unref()

    // Plain KiB -> MiB/GiB scaling helper (not a service — card-local formatting only)
    function formatKib(kib: real): string {
        if (!isFinite(kib) || kib < 0)
            return "0 KiB";
        if (kib >= 1024 * 1024)
            return (kib / (1024 * 1024)).toFixed(1) + " GiB";
        if (kib >= 1024)
            return (kib / 1024).toFixed(1) + " MiB";
        return Math.round(kib) + " KiB";
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 4

        RowLayout {
            spacing: 6

            MaterialIcon {
                text: "memory_alt"
                color: root.accent
                font.pixelSize: 18
                fill: 1
            }

            Text {
                text: "Memory"
                color: Colors.text
                font.pixelSize: 15
                font.bold: true
            }
        }

        CircularProgress {
            Layout.topMargin: 8
            Layout.alignment: Qt.AlignHCenter

            implicitSize: usageColumn.implicitHeight + thickness + 26
            startAngle: -225
            sweepAngle: 270
            strokeWidth: 7
            value: SystemUsage.memoryPercentage
            fgColor: root.accent

            ColumnLayout {
                id: usageColumn
                anchors.centerIn: parent
                spacing: -2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(SystemUsage.memoryPercentage * 100) + "%"
                    color: root.accent
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Used"
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.formatKib(SystemUsage.memoryUsedKib) + " / " + root.formatKib(SystemUsage.memoryTotalKib)
            color: Colors.text
            font.pixelSize: 12
        }
    }
}
