import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Calendar card pinned to the bottom of the sidebar column
Rectangle {
    id: root

    readonly property bool collapsed: Config.sidebar.calendarCollapsed

    radius: Motion.rounding.large
    color: Colors.layer
    clip: true

    implicitHeight: root.collapsed ? collapsedRow.implicitHeight + 24 : grid.implicitHeight + 32

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.smoothDuration; easing.type: Motion.smoothEasing }
    }

    CalendarGrid {
        id: grid

        anchors.fill: parent
        anchors.margins: 16
        showTodayButton: false
        cellSpacing: 5
        // Row height and marker size only; cell width stretches to fill the column
        cellSize: 36
        // Room for the collapse chevron at the head of the nav row
        headerLeftInset: 30

        opacity: root.collapsed ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
        }
    }

    // Collapsed state: chevron and the date on one line
    RowLayout {
        id: collapsedRow

        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        opacity: root.collapsed ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
        }

        Item {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
        }

        StyledText {
            Layout.fillWidth: true
            text: Time.dateStr
            font.pixelSize: Motion.fontSize.subhead
        }
    }

    // Sits above both states so it stays clickable through the cross-fade
    Rectangle {
        id: chevron

        anchors { left: parent.left; top: parent.top; margins: 12 }
        implicitWidth: 26
        implicitHeight: 26
        radius: width / 2
        color: chevronArea.containsMouse ? Colors.outline : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.collapsed ? "keyboard_arrow_up" : "keyboard_arrow_down"
            color: Colors.text
            font.pixelSize: Motion.fontSize.header
        }

        MouseArea {
            id: chevronArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.sidebar.calendarCollapsed = !Config.sidebar.calendarCollapsed
        }
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
