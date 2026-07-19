import "."
import QtQuick
import QtQuick.Layouts
import "../../../services"

// Storage usage ring + used/total for the primary (root-containing) physical
// disk — multiple mounts on one disk are merged by Storage.qml, not shown as
// separate partitions. Auto-hides when no disks are found, same pattern as
// BatteryCard/GpuCard.
Rectangle {
    id: root

    readonly property var disk: Storage.primaryDisk
    readonly property bool hasDisk: disk !== null

    visible: hasDisk
    implicitWidth: hasDisk ? 260 : 0
    implicitHeight: hasDisk ? 140 : 0

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: Storage.ref()
    Component.onDestruction: Storage.unref()

    // Plain KiB -> MiB/GiB scaling helper, same shape as MemoryCard.qml's
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
        visible: root.hasDisk

        UsageRing {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            value: root.disk?.percentage ?? 0
            ringColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round((root.disk?.percentage ?? 0) * 100) + "%"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Storage"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.disk ? root.formatKib(root.disk.usedKib) + " / " + root.formatKib(root.disk.totalKib) : ""
                color: Colors.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
