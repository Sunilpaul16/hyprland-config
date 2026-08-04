pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// MPRIS media state
Singleton {
    id: root

    // Player selection
    readonly property var players: {
        const raw = Mpris.players.values;
        const seen = new Map();
        for (const p of raw) {
            const key = (p.dbusName ?? "").replace(/\.instance\d+$/, "") || p.dbusName;
            const existing = seen.get(key);
            if (!existing || (p.isPlaying && !existing.isPlaying))
                seen.set(key, p);
        }
        return [...seen.values()];
    }
    property var manualPlayer: null
    readonly property bool hasManualPlayer: root.manualPlayer !== null && root.players.includes(root.manualPlayer)
    readonly property bool hasMultiplePlayers: root.players.length > 1
    readonly property var activePlayer: root.hasManualPlayer ? root.manualPlayer : (players.find(p => p.isPlaying) ?? players[0] ?? null)

    function selectPlayer(player: var): void {
        root.manualPlayer = player;
    }

    function clearPlayerOverride(): void {
        root.manualPlayer = null;
    }

    // Playback state
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0

    // Capability flags
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false

    // Shuffle and loop
    readonly property bool shuffleSupported: (activePlayer?.canControl ?? false) && (activePlayer?.shuffleSupported ?? false)
    readonly property bool shuffle: activePlayer?.shuffle ?? false
    readonly property bool loopSupported: (activePlayer?.canControl ?? false) && (activePlayer?.loopSupported ?? false)
    readonly property int loopState: activePlayer?.loopState ?? MprisLoopState.None

    // Transport controls
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

    function toggleShuffle(): void {
        if (root.shuffleSupported)
            root.activePlayer.shuffle = !root.activePlayer.shuffle;
    }

    // None -> Track -> Playlist -> None
    function cycleLoopState(): void {
        if (!root.loopSupported)
            return;
        const order = [MprisLoopState.None, MprisLoopState.Track, MprisLoopState.Playlist];
        const next = order[(order.indexOf(root.activePlayer.loopState) + 1) % order.length];
        root.activePlayer.loopState = next;
    }

    // Position tick
    Timer {
        running: root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.activePlayer?.positionChanged()
    }

    // Cover art
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool artIsRemote: artUrl.startsWith("http://") || artUrl.startsWith("https://")
    readonly property string artCacheDir: Directories.mediaArtCache
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

    // Download remote art
    Process {
        id: artDownloader
        property string pendingUrl: ""
        property string pendingDest: ""
        // Pinned escaped command
        command: ["bash", "-c", `mkdir -p "$(dirname '${StringUtils.shellSingleQuoteEscape(pendingDest)}')" && { [ -f '${StringUtils.shellSingleQuoteEscape(pendingDest)}' ] || curl -4 -sSL '${StringUtils.shellSingleQuoteEscape(pendingUrl)}' -o '${StringUtils.shellSingleQuoteEscape(pendingDest)}'; }`]
        onExited: exitCode => {
            root.artDownloaded = (exitCode === 0);
        }
    }

    // Cache dir prune
    Process {
        running: true
        command: ["bash", "-c", `mkdir -p '${Directories.mediaArtCache}' && find '${Directories.mediaArtCache}' -type f -mtime +14 -delete 2>/dev/null`]
    }
}
