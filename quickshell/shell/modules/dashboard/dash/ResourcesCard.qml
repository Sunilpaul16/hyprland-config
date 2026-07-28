import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../performance"
import "../../../components"

// Compact CPU/memory/disk summary — three small rings. CPU/memory bind to
// the same services/SystemUsage.qml singleton the Performance tab's
// CpuCard/MemoryCard already poll; disk binds to Storage.primaryDisk (no
// new polling started here for any of the three).
Rectangle {
    id: root

    // Rotates a colour's hue, passing achromatic colours through untouched
    function hueShift(c: color, degrees: real): color {
        if (c.hslSaturation <= 0.01)
            return c;
        return Qt.hsla((c.hslHue * 360 + degrees + 360) % 360 / 360, c.hslSaturation, c.hslLightness, c.a);
    }

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
            ringColor: root.hueShift(Colors.primary, 40)
        }

        Ring {
            visible: Storage.primaryDisk !== null
            value: Storage.primaryDisk?.percentage ?? 0
            icon: "hard_disk"
            ringColor: root.hueShift(Colors.primary, -30)
        }
    }

    // Icon-in-ring style (caelestia's Resources widget) — the arc alone
    // conveys the percentage, no numeric label. Rings grow with the card
    // height up to the configured ceiling, matching caelestia's fillHeight.
    component Ring: UsageRing {
        id: ringItem

        required property string icon

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.maximumHeight: Config.dashboard.resourceRing.size
        Layout.preferredWidth: height
        thickness: Config.dashboard.resourceRing.thickness
        trackColor: Qt.tint(Colors.surface, Qt.alpha(Colors.outline, 0.45))

        MaterialIcon {
            anchors.centerIn: parent
            text: ringItem.icon
            font.pixelSize: Math.round(ringItem.height * 0.36)
            color: ringItem.ringColor
        }
    }
}
