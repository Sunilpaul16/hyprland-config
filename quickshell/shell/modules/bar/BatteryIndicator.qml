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
        : Colors.readable(Colors.primary)

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
        text: {
            if (!BatteryState.onBattery)
                return "Plugged in · " + BatteryState.stateLabel;
            const seconds = BatteryState.device.timeToEmpty;
            if (!Number.isFinite(seconds) || seconds <= 0)
                return "Battery time estimate unavailable";
            const minutes = Math.max(1, Math.round(seconds / 60));
            const hours = Math.floor(minutes / 60);
            const remainder = minutes % 60;
            const duration = hours > 0
                ? hours + "h" + (remainder > 0 ? " " + remainder + "m" : "")
                : minutes + "m";
            return "About " + duration + " remaining";
        }
    }
}
