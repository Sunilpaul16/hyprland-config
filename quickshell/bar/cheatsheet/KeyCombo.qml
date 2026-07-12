import QtQuick
import "../"

Row {
    id: root

    required property var rowData

    spacing: 4

    readonly property var keyLabels: ({
        "Grave": "`",
        "Slash": "/",
        "Minus": "-",
        "Equal": "=",
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
        "XF86MonBrightnessUp": "Bright +",
        "XF86MonBrightnessDown": "Bright -",
        "XF86AudioNext": "Next",
        "XF86AudioPause": "Pause",
        "XF86AudioPlay": "Play",
        "XF86AudioPrev": "Prev"
    })

    function modNames(modmask) {
        const names = [];
        if (modmask & (1 << 2)) names.push("Ctrl");
        if (modmask & (1 << 6)) names.push("Super");
        if (modmask & (1 << 0)) names.push("Shift");
        if (modmask & (1 << 3)) names.push("Alt");
        return names;
    }

    readonly property var mods: modNames(rowData.modmask)
    readonly property string mainKey: rowData.isRange ? `${rowData.keys[0]}-${rowData.keys[1]}` : (keyLabels[rowData.keys[0]] ?? rowData.keys[0])

    Repeater {
        model: root.mods

        Row {
            required property string modelData
            spacing: 4

            KeyCap { label: modelData }
            Item {
                implicitWidth: plus.implicitWidth
                implicitHeight: 20
                Text { id: plus; anchors.centerIn: parent; text: "+"; color: Colors.textMuted; font.pixelSize: 11 }
            }
        }
    }

    KeyCap { label: root.mainKey }
}
