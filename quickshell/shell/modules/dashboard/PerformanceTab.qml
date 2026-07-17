import "performance"
import QtQuick
import QtQuick.Layouts
import "../../services"

// Performance tab: CPU / Memory / Network / Battery cards. Each card is
// loaded through its own file-based Loader (not a direct type import) so a
// broken/missing card file only takes down that one slot — Loader.status
// isolates load-time failures from the rest of the tab, unlike inline
// component instantiation which would fail the whole file.
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
    }

    // Wraps a card file's Loader with fault isolation (Loader.Error shows a
    // small fallback instead of a blank gap) and lets a card's own
    // intentional `visible: false` (e.g. BatteryCard with no battery)
    // collapse the grid cell entirely rather than reserving empty space.
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
