import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../performance"
import "../../../components"

// Compact CPU/memory/disk summary in three small rings — binds to the SystemUsage and Storage singletons the Performance tab already polls, starting no new polling
Rectangle {
    id: root

    // Rotates a colour's hue, passing achromatic colours through untouched
    radius: Motion.rounding.large
    color: Colors.layer
    border.width: 1
    border.color: Colors.outline
    implicitWidth: Config.dashboard.resourceRing.size + 24
    implicitHeight: content.implicitHeight + 24

    Component.onCompleted: {
        SystemUsage.ref();
        Storage.ref();
    }
    Component.onDestruction: {
        SystemUsage.unref();
        Storage.unref();
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Ring {
            value: SystemUsage.cpuPercentage
            icon: "memory"
            ringColor: Colors.primary
        }

        Ring {
            value: SystemUsage.memoryPercentage
            icon: "memory_alt"
            ringColor: Colors.hueShift(Colors.primary, 40)
        }

        Ring {
            visible: Storage.primaryDisk !== null
            value: Storage.primaryDisk?.percentage ?? 0
            icon: "hard_disk"
            ringColor: Colors.hueShift(Colors.primary, -30)
        }
    }

    // Icon-in-ring: the arc alone conveys the percentage, growing with card height up to the configured ceiling
    component Ring: UsageRing {
        id: ringItem

        required property string icon

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.maximumHeight: Config.dashboard.resourceRing.size
        Layout.preferredWidth: height
        thickness: Config.dashboard.resourceRing.thickness
        trackColor: Colors.tint(Colors.surface, Colors.outline, 0.45)

        MaterialIcon {
            anchors.centerIn: parent
            text: ringItem.icon
            font.pixelSize: Math.round(ringItem.height * 0.36)
            color: ringItem.ringColor
        }
    }
}
