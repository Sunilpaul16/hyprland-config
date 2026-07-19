import "performance"
import QtQuick
import QtQuick.Layouts
import "../../services"

// Performance tab: CPU / Memory / Network / Battery / GPU / Storage cards.
// Each card loads through its own file Loader for fault isolation — a
// broken card file only takes down that one slot.
Item {
    id: root

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 12
        columnSpacing: 12

        CardSlot { source: "performance/CpuCard.qml" }
        CardSlot { source: "performance/MemoryCard.qml" }
        CardSlot { source: "performance/NetworkCard.qml" }
        CardSlot { source: "performance/BatteryCard.qml" }
        CardSlot { source: "performance/GpuCard.qml" }
        CardSlot { source: "performance/StorageCard.qml" }
    }

    // Wraps a card's Loader with fault isolation (load errors show a small
    // fallback) and collapses the grid cell when a card sets `visible: false`.
    component CardSlot: Item {
        id: slot

        required property string source

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 260
        Layout.preferredHeight: 140

        visible: inner.status === Loader.Error || (inner.item?.visible ?? true)

        Loader {
            id: inner
            anchors.fill: parent
            source: slot.source
        }

        Rectangle {
            anchors.fill: parent
            visible: inner.status === Loader.Error
            radius: 18
            color: Colors.surface
            border.width: 1
            border.color: Colors.error

            Text {
                anchors.centerIn: parent
                text: "Unavailable"
                color: Colors.error
                font.pixelSize: 13
            }
        }
    }
}
