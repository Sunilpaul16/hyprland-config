pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire


Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
