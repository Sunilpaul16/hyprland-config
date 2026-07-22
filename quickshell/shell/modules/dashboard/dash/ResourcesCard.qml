import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../performance"

// Compact CPU/memory/disk summary — three small rings. CPU/memory bind to
// the same services/SystemUsage.qml singleton the Performance tab's
// CpuCard/MemoryCard already poll; disk binds to Storage.primaryDisk (no
// new polling started here for any of the three).
Rectangle {
    id: root

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: {
        SystemUsage.ref();
        Storage.ref();
    }
    Component.onDestruction: {
        SystemUsage.unref();
        Storage.unref();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Ring {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            value: SystemUsage.cpuPercentage
            icon: "memory"
        }

        Ring {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            value: SystemUsage.memoryPercentage
            icon: "memory_alt"
        }

        Ring {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            visible: Storage.primaryDisk !== null
            value: Storage.primaryDisk?.percentage ?? 0
            icon: "hard_disk"
        }
    }

    // Icon-in-ring style (caelestia's Resources widget) — the arc alone
    // conveys the percentage, no numeric label
    component Ring: UsageRing {
        id: ringItem

        required property string icon

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        thickness: Config.dashboardResourceRingThickness
        ringColor: Colors.primary

        Text {
            anchors.centerIn: parent
            text: ringItem.icon
            font.family: "Material Symbols Rounded"
            font.pixelSize: 16
            color: Colors.primary
        }
    }
}
