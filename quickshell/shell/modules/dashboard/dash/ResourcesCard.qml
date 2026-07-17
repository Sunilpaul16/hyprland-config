import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../performance"

// Compact CPU/memory summary — two small rings bound to the same
// services/SystemUsage.qml singleton the Performance tab's CpuCard/
// MemoryCard already poll (no new polling started here). Storage skipped —
// no Storage service exists yet (tier 2 follow-up).
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: SystemUsage.ref()
    Component.onDestruction: SystemUsage.unref()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Ring {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            value: SystemUsage.cpuPercentage
            label: "CPU"
        }

        Ring {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            value: SystemUsage.memoryPercentage
            label: "MEM"
        }
    }

    component Ring: ColumnLayout {
        id: ringItem

        required property real value
        required property string label

        spacing: 4

        UsageRing {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            thickness: 4
            value: ringItem.value
            ringColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round(ringItem.value * 100) + "%"
                color: Colors.text
                font.pixelSize: 10
                font.bold: true
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: ringItem.label
            color: Colors.textMuted
            font.pixelSize: 10
        }
    }
}
