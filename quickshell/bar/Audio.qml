pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Trimmed port of end-4/caelestia's services/Audio.qml, stripped to just
// what the volume OSD needs: current sink's volume + mute state. No
// sources/streams/sink-switching/toast-on-device-change -- this repo has
// no Config/Tokens/Toaster to drive those with, and the OSD only cares
// about the default output.
//
// Route taken: Quickshell.Services.Pipewire, not a wpctl polling loop.
// Checked first: the module is installed (/usr/lib/qt6/qml/Quickshell/
// Services/Pipewire), pipewire+wireplumber are running live on this
// machine (confirmed via pgrep), and PwNodeAudioIface's volume/muted are
// real writable Qt properties with their own change signals
// (volumesChanged/mutedChanged, confirmed in quickshell-service-pipewire.
// qmltypes) -- genuinely reactive, the same primitive caelestia's own
// Audio.qml is built on. No polling anywhere.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    // PwObjectTracker is what actually keeps a PwNode's properties (audio
    // interface included) bound/updating -- without tracking it, `sink`
    // resolves once and its `.audio.volume`/`.muted` won't stay live.
    // Retracked automatically whenever the default sink itself changes
    // (e.g. plugging in headphones), since `objects` is a fresh array each
    // time this binding re-evaluates.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
