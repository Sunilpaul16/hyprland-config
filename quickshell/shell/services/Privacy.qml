pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Mic and screencast
Singleton {
    id: root

    // Capture stream count
    readonly property int micCount: Pipewire.linkGroups.values.filter(g => g.source?.type === PwNodeType.AudioSource && g.target?.type === PwNodeType.AudioInStream).length
    readonly property int screencastCount: Pipewire.linkGroups.values.filter(g => g.source?.type === PwNodeType.VideoSource).length

    readonly property bool micActive: root.micCount > 0
    readonly property bool screencastActive: root.screencastCount > 0
    readonly property bool active: root.micActive || root.screencastActive
}
