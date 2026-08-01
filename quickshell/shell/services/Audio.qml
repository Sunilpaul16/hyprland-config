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

    // Everything that isn't an application stream — structural, so untracked; a properties-based filter would never resolve, since `properties` is only populated for tracked nodes
    readonly property var deviceNodes: Pipewire.nodes.values.filter(n => !n.isStream)

    // Real devices, keyed on media.class not !isSink — PipeWire's support nodes (Dummy-Driver, Freewheel-Driver, Midi-Bridge) would otherwise read as pickable microphones
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

    // Sink volume, clamped [0, maxVolume] — guard NaN first, since PipeWire reports it on resume-from-suspend and Math.min/max pass it straight through
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

    // Keep sink/source bound for property updates; the device lists are tracked too, since an untracked node reports no description or volume
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.deviceNodes].filter(n => n)
    }
}
