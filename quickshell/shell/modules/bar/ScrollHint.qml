import QtQuick
import "../../services"
import "../../components"

// Fading up/icon/down affordance for a scroll-to-adjust zone
Column {
    id: root
    property bool reveal: false
    property string icon: ""

    spacing: -4
    opacity: reveal ? 1 : 0
    scale: reveal ? 1 : 0.85

    Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    Behavior on scale { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    MaterialIcon {
        text: "keyboard_arrow_up"
        font.pixelSize: Motion.fontSize.body
        color: Colors.textMuted
    }
    MaterialIcon {
        text: root.icon
        font.pixelSize: Motion.fontSize.body
        color: Colors.textMuted
    }
    MaterialIcon {
        text: "keyboard_arrow_down"
        font.pixelSize: Motion.fontSize.body
        color: Colors.textMuted
    }
}
