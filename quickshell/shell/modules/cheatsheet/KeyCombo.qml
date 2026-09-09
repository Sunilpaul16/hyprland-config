import QtQuick
import "../../services"
import "../../components"

// Key combo widget
Row {
    id: root

    required property var rowData

    spacing: Motion.spacing.tiny

    // Key labels
    readonly property var keyLabels: ({
        "Grave": "`",
        "Slash": "/",
        "Minus": "-",
        "Equal": "=",
        "period": ".",
        "comma": ",",
        "Print": "PrtSc",
        "left": "←",
        "right": "→",
        "up": "↑",
        "down": "↓",
        "mouse_up": "Scroll ↑",
        "mouse_down": "Scroll ↓",
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "XF86AudioRaiseVolume": "Vol +",
        "XF86AudioLowerVolume": "Vol -",
        "XF86AudioMute": "Mute",
        "XF86AudioMicMute": "Mic",
        "XF86AudioNext": "Next",
        "XF86AudioPause": "Pause",
        "XF86AudioPlay": "Play",
        "XF86AudioPrev": "Prev"
    })

    // Modifier bit-flag decode
    function modNames(modmask) {
        const names = [];
        if (modmask & (1 << 2)) names.push("Ctrl");
        if (modmask & (1 << 6)) names.push("Super");
        if (modmask & (1 << 0)) names.push("Shift");
        if (modmask & (1 << 3)) names.push("Alt");
        if (modmask & (1 << 5)) names.push("Right Win");
        return names;
    }

    readonly property var mods: modNames(rowData.modmask)
    readonly property string mainKey: rowData.isRange ? `${rowData.keys[0]}-${rowData.keys[1]}` : (keyLabels[rowData.keys[0]] ?? rowData.keys[0])

    // Modifier keys
    Repeater {
        model: root.mods

        Row {
            required property string modelData
            spacing: Motion.spacing.tiny

            KeyCap { label: modelData }
            Item {
                implicitWidth: plus.implicitWidth
                implicitHeight: 20
                StyledText { id: plus; anchors.centerIn: parent; text: "+"; color: Colors.textMuted; font.pixelSize: Motion.fontSize.small }
            }
        }
    }

    // Main key
    KeyCap { label: root.mainKey }
}
