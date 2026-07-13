pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Media player (MPRIS) state singleton — tracks whichever player is
// currently playing, falling back to the first available one. No
// duplicate-player filtering or manual player picking (barebones).
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var activePlayer: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0

    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false

    function togglePlaying(): void {
        if (root.canTogglePlaying)
            root.activePlayer.togglePlaying();
    }

    function previous(): void {
        if (root.canGoPrevious)
            root.activePlayer.previous();
    }

    function next(): void {
        if (root.canGoNext)
            root.activePlayer.next();
    }

    // Poke position while playing so bound UI (popup progress bar) ticks
    Timer {
        running: root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.activePlayer?.positionChanged()
    }

    // --- Cover art -----------------------------------------------------
    // file:// art is used directly; http(s) art is downloaded into a
    // cache dir first. Fetched here (once, shared) rather than per-popup
    // so it isn't re-downloaded once per monitor.
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool artIsRemote: artUrl.startsWith("http://") || artUrl.startsWith("https://")
    readonly property string artCacheDir: Quickshell.env("HOME") + "/.cache/quickshell-media-art"
    readonly property string artCacheFile: artCacheDir + "/" + Qt.md5(artUrl) + ".jpg"
    property bool artDownloaded: false

    readonly property string artSource: {
        if (artUrl.length === 0)
            return "";
        return artIsRemote ? (artDownloaded ? Qt.resolvedUrl(artCacheFile) : "") : artUrl;
    }

    onArtUrlChanged: {
        root.artDownloaded = false;
        if (!root.artIsRemote || root.artUrl.length === 0)
            return;
        artDownloader.pendingUrl = root.artUrl;
        artDownloader.pendingDest = root.artCacheFile;
        artDownloader.running = true;
    }

    Process {
        id: artDownloader
        property string pendingUrl: ""
        property string pendingDest: ""
        // Own properties (not root.artUrl directly) so the command string
        // used by a run is pinned at the moment it's launched, matching
        // end-4's MprisController pattern for this same download.
        command: ["bash", "-c", `mkdir -p "$(dirname '${pendingDest}')" && { [ -f '${pendingDest}' ] || curl -4 -sSL '${pendingUrl}' -o '${pendingDest}'; }`]
        onExited: exitCode => {
            root.artDownloaded = (exitCode === 0);
        }
    }
}
