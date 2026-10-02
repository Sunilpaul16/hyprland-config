import QtQuick
import "../../services"
import "../../components"

// Compact phone-style battery status alongside the clock.
Item {
    id: root

    visible: BatteryState.available
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight
    readonly property color statusColor: BatteryState.low ? Colors.error
        : BatteryState.pluggedIn ? Colors.readable(Colors.primary) : Colors.text

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Motion.spacing.tiny

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryState.icon
            font.pixelSize: Motion.fontSize.title
            color: root.statusColor
        }
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: BatteryState.pluggedIn && !BatteryState.charging
            text: "power"
            font.pixelSize: Motion.fontSize.title
            color: root.statusColor
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryState.percentageText
            font.pixelSize: Motion.fontSize.label + 2
            font.weight: Font.Medium
            color: root.statusColor
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }
    PopupToolTip {
        hoverTarget: root
        shown: hover.containsMouse
        text: (BatteryState.pluggedIn ? "Plugged in · " : "")
            + BatteryState.stateLabel + " · " + BatteryState.percentageText
    }
}
