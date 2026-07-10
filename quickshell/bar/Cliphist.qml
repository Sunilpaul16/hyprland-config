pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "launcher/fuzzysort.js" as Fuzzy

// Trimmed port of end-4's dots-hyprland services/Cliphist.qml, stripped of
// everything that isn't the clipboard history itself: no work-safety blur
// (that's a whole separate Network service + config-driven keyword list),
// no Levenshtein sloppy-matcher toggle -- query() below reuses
// launcher/fuzzysort.js the same way Apps.qml/Commands.qml do, not a second
// matcher), no superpaste/ydotool auto-paste chaining, no Translation
// wrappers. Prefixes/paths are plain string literals since this config has
// no Config.qml to back them.
//
// Capture itself isn't this file's job: `wl-paste --watch cliphist store`
// already runs as a standing exec-once in ~/.config/hypr/execs.lua
// (confirmed running via `pgrep -af wl-paste`), same as it always has for
// the existing SUPER+V fuzzel flow.
//
// No background refresh trigger here on purpose -- Quickshell.clipboardText
// / onClipboardTextChanged looks like the obvious hook (it's what end-4's
// debounce rides on), but verified empirically it does NOT fire for
// external clipboard changes (wl-copy, browser copies, etc): it's a local
// write-notify property that only reacts to `Quickshell.clipboardText = ...`
// from inside this same process, and its initial value is "" even when the
// real system clipboard already has content. So there's nothing to debounce
// -- refresh() is just exposed for whatever mounts this (chunk 2's launcher
// mode calls it on open, same as CheatsheetState does for Binds.qml). If
// live/background refresh is ever wanted, the real fix is end-4's approach:
// have execs.lua's watcher chain `&& qs -c bar ipc call cliphist update`
// after `cliphist store`, and add an IpcHandler here to call refresh().
Singleton {
    id: root

    readonly property string cliphistBinary: "cliphist"
    property list<string> entries: []

    // Same detection end-4 uses -- `cliphist list` prints image entries as
    // "<id>\t[[ binary data <W>x<H> <mime> ]]" instead of a text preview.
    // Just a tag for now; decoding a preview image is chunk 3's job.
    function entryIsImage(entry) {
        return /^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry);
    }

    function entryId(entry) {
        return entry.match(/^(\d+)\t/)?.[1] ?? "";
    }

    // Scratch dir for lazily-decoded image thumbnails (ClipItem.qml), same
    // idea as end-4's CliphistImage.qml: decode-on-mount, delete-on-unmount,
    // nothing persisted between shell restarts -- wiped once here at
    // startup so a previous session's leftovers (if the shell ever crashed
    // mid-decode) don't linger.
    readonly property string decodeDir: "/tmp/quickshell-bar-cliphist"

    // What the launcher shows/matches against: the leading "<id>\t" is
    // stripped (kept only in the raw `entry` string for copy/delete, which
    // need the exact `cliphist list` line). Image entries get a plain
    // "[image WxH mime]" placeholder in place of the binary-data marker --
    // this label is kept even once ClipItem.qml renders a real thumbnail
    // next to it.
    function displayText(entry) {
        if (root.entryIsImage(entry)) {
            const dims = entry.match(/(\d+)x(\d+)/);
            // Field order in the "[[ binary data ... ]]" marker isn't fixed
            // -- confirmed on this machine it's "<size> <unit> <mime>
            // <W>x<H>" (e.g. "binary data 313 B png 40x30"), not the
            // "<W>x<H> <mime>" order docs/examples elsewhere assume. Match
            // the mime keyword itself rather than its position.
            const mime = entry.match(/\b(png|jpe?g|gif|bmp|webp|tiff?)\b/i)?.[1] ?? "image";
            return dims ? `[image ${dims[1]}x${dims[2]} ${mime}]` : "[image]";
        }
        return entry.replace(/^\d+\t/, "");
    }

    // Rows carry both the display text (what's matched/shown) and the raw
    // entry (what copy()/deleteEntry() need) -- same shape Apps.qml's
    // query() returns, just with an extra `entry`/`isImage` field alongside
    // the fuzzysort-matched `text`.
    function query(search: string): var {
        const rows = root.entries.map(entry => ({
            entry,
            text: root.displayText(entry),
            isImage: root.entryIsImage(entry)
        }));
        const trimmed = search.trim();
        if (!trimmed)
            return rows;
        return Fuzzy.go(trimmed, rows, { key: "text", all: true }).map(r => r.obj);
    }

    function refresh() {
        listProc.buffer = [];
        listProc.running = true;
    }

    function copy(entry) {
        copyProc.pendingEntry = entry;
        copyProc.stdinEnabled = true;
        copyProc.running = true;
    }

    function deleteEntry(entry) {
        deleteProc.pendingEntry = entry;
        deleteProc.stdinEnabled = true;
        deleteProc.running = true;
    }

    function wipe() {
        wipeProc.running = true;
    }

    Component.onCompleted: {
        root.refresh();
        wipeDecodeDirProc.running = true;
    }

    Process {
        id: wipeDecodeDirProc
        command: ["bash", "-c", `rm -rf '${root.decodeDir}'; mkdir -p '${root.decodeDir}'`]
    }

    Process {
        id: listProc
        property list<string> buffer: []
        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: line => listProc.buffer.push(line)
        }

        onExited: exitCode => {
            if (exitCode === 0)
                root.entries = listProc.buffer;
            else
                console.error("[Cliphist] `cliphist list` failed with code", exitCode);
        }
    }

    // Entry text goes straight to the child's stdin (Process.write), not
    // interpolated into a shell string -- no escaping needed at all this
    // way, unlike end-4's printf/echo + manual single-quote-escape approach
    // (their StringUtils.shellSingleQuoteEscape). `stdinEnabled` has to be
    // flipped back on before each run and off again right after writing --
    // it's a plain property, not a one-shot binding, so a prior run leaves
    // it false; and `cliphist decode`/`delete` both read stdin until EOF,
    // which only happens once stdinEnabled goes false (confirmed empirically
    // with a throwaway qs -p script -- without this they hang forever
    // waiting for more input, silently doing nothing).
    Process {
        id: copyProc
        property string pendingEntry: ""
        command: ["bash", "-c", `${root.cliphistBinary} decode | wl-copy`]
        onStarted: {
            copyProc.write(copyProc.pendingEntry + "\n");
            copyProc.stdinEnabled = false;
        }
    }

    Process {
        id: deleteProc
        property string pendingEntry: ""
        command: [root.cliphistBinary, "delete"]
        onStarted: {
            deleteProc.write(deleteProc.pendingEntry + "\n");
            deleteProc.stdinEnabled = false;
        }
        onExited: root.refresh()
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: root.refresh()
    }
}
