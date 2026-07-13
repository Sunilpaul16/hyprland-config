pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire


// Audio state singleton
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    // Keep sink bound for property updates
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
