import QtQuick
import "../../services"
import "../../components"

// Calendar card pinned to the bottom of the sidebar column
Rectangle {
    id: root

    radius: Motion.rounding.large
    color: Colors.layer
    clip: true

    implicitHeight: grid.implicitHeight + 32

    CalendarGrid {
        id: grid

        anchors.fill: parent
        anchors.margins: 16
        showTodayButton: false
        cellSpacing: 5
        // Row height and marker size only; cell width stretches to fill the column
        cellSize: 36
    }

    // The sidebar's LazyLoader keeps this alive between opens, so a month
    // navigated to earlier would otherwise still be showing on the next open
    Connections {
        target: SidebarRightState

        function onOpenChanged() {
            if (SidebarRightState.open)
                grid.goToToday();
        }
    }
}
