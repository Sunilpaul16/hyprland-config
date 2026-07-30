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
    readonly property real volume: isNaN(sink?.audio?.volume) ? 0 : sink.audio.volume

    // Ceiling for both setters and every slider that drives them. 1.5 rather than
    // a larger boost because most sinks clip hard above it
    readonly property real maxVolume: Config.audio.allowBoost ? 1.5 : 1

    // Source (mic input)
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micMuted: !!source?.audio?.muted
    readonly property real sourceVolume: isNaN(source?.audio?.volume) ? 0 : source.audio.volume

    function toggleMicMute(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // isSink here means "plays into the sink" (a stream), not "is the sink itself"
    readonly property var outputAppNodes: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)
    readonly property var inputAppNodes: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink)

    function appNodeDisplayName(node): string {
        return node.properties["application.name"] ?? node.description ?? node.name;
    }

    // Everything that isn't an application stream. Structural, so it needs no
    // tracking — which matters, because `properties` below is only populated
    // for tracked nodes, and deriving the track list from a properties filter
    // would never resolve
    readonly property var deviceNodes: Pipewire.nodes.values.filter(n => !n.isStream)

    // Real devices. media.class, not !isSink — PipeWire's own support nodes
    // (Dummy-Driver, Freewheel-Driver, Midi-Bridge) are neither streams nor
    // sinks, so they'd otherwise be offered as pickable microphones
    readonly property var sinks: root.deviceNodes.filter(n => n.properties?.["media.class"] === "Audio/Sink")
    readonly property var sources: root.deviceNodes.filter(n => n.properties?.["media.class"] === "Audio/Source")

    function deviceDisplayName(node): string {
        return node?.nickname || node?.description || node?.name || "";
    }

    // Writing `preferred*` is how the default is changed; `defaultAudioSink`
    // itself is read-only and follows it once PipeWire agrees
    function setSink(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Sink volume — clamped [0, maxVolume]. PipeWire can report NaN on
    // resume-from-suspend; Math.min/max propagate it straight through the
    // clamp, so guard before it reaches the sink.
    function setVolume(newVolume: real): void {
        if (isNaN(newVolume))
            return;
        if (sink?.ready && sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(root.maxVolume, newVolume));
    }

    // Unmutes before raising, matching kbVolumeUp's set-mute-then-raise;
    // decrementVolume deliberately doesn't touch mute, matching kbVolumeDown
    function incrementVolume(): void {
        if (Config.audio.unmuteOnChange && sink?.ready && sink?.audio)
            sink.audio.muted = false;
        setVolume(volume + Config.audio.volumeStep);
    }

    function decrementVolume(): void {
        setVolume(volume - Config.audio.volumeStep);
    }

    function unmuteVolume(): void {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = false;
    }

    // Source (mic) volume — same clamp/step convention as sink, no existing
    // keybind precedent to match for mic level specifically
    function setSourceVolume(newVolume: real): void {
        if (isNaN(newVolume))
            return;
        if (source?.ready && source?.audio)
            source.audio.volume = Math.max(0, Math.min(root.maxVolume, newVolume));
    }

    function incrementSourceVolume(): void {
        if (Config.audio.unmuteOnChange && source?.ready && source?.audio)
            source.audio.muted = false;
        setSourceVolume(sourceVolume + Config.audio.volumeStep);
    }

    function decrementSourceVolume(): void {
        setSourceVolume(sourceVolume - Config.audio.volumeStep);
    }

    function unmuteSourceVolume(): void {
        if (source?.ready && source?.audio)
            source.audio.muted = false;
    }

    // Keep sink/source bound for property updates. The device lists are
    // tracked too — an untracked node reports no description or volume, so
    // a device picker would show blank rows
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.deviceNodes].filter(n => n)
    }
}
