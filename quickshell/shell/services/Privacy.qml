pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Mic and screencast activity, for the bar's privacy indicator.
// Camera is deliberately not covered: /dev/video* does not exist on this box, so the
// state could never be exercised and a permanently-false indicator would just be a lie
Singleton {
    id: root

    // A capture stream is a link from a real source node to a stream node. Counted, not
    // mapped: end-4's equivalent assigns the .map() array straight to a bool property, and
    // an empty array coerces to true in QML, so theirs reads "in use" permanently
    readonly property int micCount: Pipewire.linkGroups.values.filter(g => g.source?.type === PwNodeType.AudioSource && g.target?.type === PwNodeType.AudioInStream).length
    readonly property int screencastCount: Pipewire.linkGroups.values.filter(g => g.source?.type === PwNodeType.VideoSource).length

    readonly property bool micActive: root.micCount > 0
    readonly property bool screencastActive: root.screencastCount > 0
    readonly property bool active: root.micActive || root.screencastActive
}
