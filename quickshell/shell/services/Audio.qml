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

    // Volume ceiling
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

    // App output streams
    readonly property var outputAppNodes: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)
    readonly property var inputAppNodes: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink)

    function appNodeDisplayName(node): string {
        return node.properties["application.name"] ?? node.description ?? node.name;
    }

    // Device nodes
    readonly property var deviceNodes: Pipewire.nodes.values.filter(n => !n.isStream)

    // Real sinks
    readonly property var sinks: root.deviceNodes.filter(n => n.properties?.["media.class"] === "Audio/Sink")
    readonly property var sources: root.deviceNodes.filter(n => n.properties?.["media.class"] === "Audio/Source")

    function deviceDisplayName(node): string {
        return node?.nickname || node?.description || node?.name || "";
    }

    // Set default sink
    function setSink(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Clamped sink volume
    function setVolume(newVolume: real): void {
        if (isNaN(newVolume))
            return;
        if (sink?.ready && sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(root.maxVolume, newVolume));
    }

    // Unmute on raise
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

    // Mic volume
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

    // Object tracking
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.deviceNodes].filter(n => n)
    }
}
