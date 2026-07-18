pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire


// Audio state singleton
Singleton {
    id: root

    // Sink (output)
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    // Source (mic input)
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    function toggleMicMute(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    // Sink volume — clamped [0, 1], matching the existing keybind's -l 1 cap
    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, newVolume));
    }

    // Unmutes before raising, matching kbVolumeUp's set-mute-then-raise;
    // decrementVolume deliberately doesn't touch mute, matching kbVolumeDown
    function incrementVolume(): void {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = false;
        setVolume(volume + 0.05);
    }

    function decrementVolume(): void {
        setVolume(volume - 0.05);
    }

    function unmuteVolume(): void {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = false;
    }

    // Source (mic) volume — same clamp/step convention as sink, no existing
    // keybind precedent to match for mic level specifically
    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio)
            source.audio.volume = Math.max(0, Math.min(1, newVolume));
    }

    function incrementSourceVolume(): void {
        if (source?.ready && source?.audio)
            source.audio.muted = false;
        setSourceVolume(sourceVolume + 0.05);
    }

    function decrementSourceVolume(): void {
        setSourceVolume(sourceVolume - 0.05);
    }

    function unmuteSourceVolume(): void {
        if (source?.ready && source?.audio)
            source.audio.muted = false;
    }

    // Keep sink/source bound for property updates
    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }
}
